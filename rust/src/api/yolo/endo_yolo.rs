use anyhow::anyhow;
use image::{DynamicImage, GenericImage, GenericImageView};
use ndarray::{ArrayView, Ix3, s};
use ort::error::Result;
use ort::inputs;
use ort::session::builder::SessionBuilder;
use ort::session::{Session, SessionOutputs};
use ort::value::{Tensor, Value};

/// Прямоугольник, ограничивающий обнаруженный объект.
///
/// Хранит координаты двух углов: верхнего левого (`x1`, `y1`) и нижнего правого (`x2`, `y2`).
#[derive(Debug, Copy, Clone)]
pub struct BoundingBox {
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32
}

impl BoundingBox {
    pub fn new(x1: f32, y1: f32, x2: f32, y2: f32) -> Self {
        Self{
            x1, y1, x2, y2
        }
    }

    pub fn intersection(&self, other: &Self) -> f32 {
        let x_overlap = (self.x2.min(other.x2) - self.x1.max(other.x1)).max(0.0);
        let y_overlap = (self.y2.min(other.y2) - self.y1.max(other.y1)).max(0.0);
        x_overlap * y_overlap
    }

    pub fn union(&self, other: &Self) -> f32 {
        let self_area = (self.x2 - self.x1) * (self.y2 - self.y1);
        let other_area = (other.x2 - other.x1) * (other.y2 - other.y1);
        self_area + other_area - self.intersection(other)
    }

    pub fn iou(&self, other: &Self) -> f32 {
        let intersection = self.intersection(other);
        if intersection == 0. {
            0.
        } else {
            intersection / self.union(other)
        }
    }
}

/// Представляет предсказание объекта.
///
/// # Поля
///
/// * `label` — строка с меткой класса (напр., `"polyp"`);
/// * `confidence` — уверенность модели (0.0 — 1.0);
/// * `bbox` — кортеж `(x_1, y_1, x_2, y_2)` в пикселях.
///
/// # Пример
/// ```rust
/// DetectionResult {
///     label: "polyp".to_string(),
///     confidence: 0.92,
///     bbox: (100, 50, 200, 150),
/// }
/// ```

#[derive(Debug, Clone)]
pub struct DetectionResult {
    pub bbox: BoundingBox,
    pub label: String,
    pub confidence: f32,
}

/// Интерфейс для работы с YOLO-моделью через ONNX Runtime.
///
/// Обрабатывает изображение, выполняет инференс и постобработку (NMS).
pub struct YOLO {
    session: Session,
    class_labels: Vec<String>,
    confidence_threshold: f32,
    nms_threshold: f32,
}

impl YOLO {
    /// Создаёт новый экземпляр YOLO-модели на основе ONNX-файла.
    ///
    /// # Аргументы
    ///
    /// * `model_path` — путь к ONNX-модели;
    /// * `class_labels` — вектор строк с метками классов;
    /// * `confidence_threshold` — минимальный порог уверенности для вывода детекций;
    /// * `nms_threshold` — порог для non-maximum suppression.
    ///
    /// # Возвращает
    ///
    /// `Result<YOLO>` — возвращает экземпляр YOLO при успешной инициализации, иначе ошибку.
    ///
    /// # Ошибки
    ///
    /// Возникает, если не удаётся загрузить ONNX-модель, или если модель не соответствует ожидаемому формату.
    ///
    /// # Пример
    /// ```rust
    /// let class_labels = vec![
    ///     "polyp".to_string(),
    ///     "other_class".to_string(),
    /// ];
    /// let yolo = YOLO::new("./best.onnx", class_labels, 0.25, 0.7)?;
    /// ```

    pub fn new(
        model_path: &str,
        class_labels: Vec<String>,
        confidence_threshold: f32,
        nms_threshold: f32,
    ) -> Result<Self> {
        //let environment = EnvironmentBuilder::
          //  .with_execution_providers([ExecutionProvider::CUDA(Default::default())])
            //.build()?;

        let session = SessionBuilder::new()?
            .commit_from_file(model_path)?;
            //Session::builder()?.commit_from_file(model_path)?;

        Ok(Self{
            session,
            class_labels,
            confidence_threshold,
            nms_threshold
        })
    }

    /// Изменяет размер изображения с сохранением соотношения сторон и добавляет padding
    ///
    /// Возвращает обработанное изображение, отступы по X/Y и коэффициент масштабирования
    pub fn letterbox(
        &self,
        image: &DynamicImage,
        target_size: (u32, u32),
    ) -> (DynamicImage, (f32, f32), f32) {
        let (target_w, target_h) = target_size;
        let (img_w, img_h) = (image.width() as f32, image.height() as f32);

        let scale = (target_w as f32 / img_w).min(target_h as f32 / img_h);
        let new_w = (img_w * scale).round() as u32;
        let new_h = (img_h * scale).round() as u32;

        let resized = image.resize_exact(
            new_w,
            new_h,
            image::imageops::CatmullRom
        );

        let mut canvas = DynamicImage::new_rgb8(target_w, target_h);
        for y in 0..target_h {
            for x in 0..target_w {
                canvas.put_pixel(x, y, image::Rgba([114, 114, 114, 255]));
            }
        }

        let pad_x = ((target_w - new_w) as f32 / 2.0).round() as i64;
        let pad_y = ((target_h - new_h) as f32 / 2.0).round() as i64;
        image::imageops::overlay(&mut canvas, &resized, pad_x, pad_y);

        (canvas, (pad_x as f32, pad_y as f32), scale)
    }

    fn image_to_tensor(&self, image: &DynamicImage) -> Result<Value> {
        let (width, height) = (image.width() as usize, image.height() as usize);

        let mut data = Vec::with_capacity(3 * height * width);

        for c in 0..3 {
            for y in 0..height {
                for x in 0..width {
                    let pixel = image.get_pixel(x as u32, y as u32);
                    let value = match c {
                        0 => pixel.0[0] as f32 / 255.0,  // R
                        1 => pixel.0[1] as f32 / 255.0,  // G
                        2 => pixel.0[2] as f32 / 255.0,  // B
                        _ => unreachable!(),
                    };
                    data.push(value);
                }
            }
        }
        // Создаем тензор с размерностью [1, 3, height, width]
        let tensor = Tensor::from_array(([1, 3, height, width], data))
            .map_err(|e| anyhow::anyhow!("Tensor creation failed: {}", e))
            .expect("Tensor Failed while converting image to tensor");
        Ok(Value::from(tensor))
    }

    /// Выполняет предсказание объектов на изображении.
    ///
    /// # Аргументы
    ///
    /// * `img` — изображение (`DynamicImage`), на котором будет выполнено предсказание.
    ///
    /// # Возвращает
    ///
    /// `Result<Vec<Detection>>` — список предсказанных объектов (`label`, `confidence`, `bbox`).
    ///
    /// # Ошибки
    ///
    /// Возвращает ошибку, если входное изображение не может быть преобразовано к формату,
    /// подходящему для модели, либо если инференс не удался.
    ///
    /// # Пример
    /// ```rust
    /// let img = image::open("example.jpg")?;
    /// let detections = yolo.predict(&img)?;
    /// for det in detections {
    ///     println!("{}: {:.2}, {:?}", det.label, det.confidence, det.bbox);
    /// }
    /// ```
    pub fn predict(&mut self, image: &DynamicImage) -> Result<Vec<DetectionResult>> {
        let (orig_w, orig_h) = (image.width() as f32, image.height() as f32);
        let (processed, (pad_x, pad_y), scale) = self.letterbox(image, (640, 640));
        let input_tensor = self.image_to_tensor(&processed)?;

        let output_owned: ndarray::Array3<f32> = {
            let raw: SessionOutputs<'_> =
                self.session.run(inputs!["images" => input_tensor.view()])?;

            let arr = raw["output0"]
                .try_extract_array::<f32>()
                .map_err(|e| anyhow!("Extract failed: {}", e)).unwrap();

            arr.view()
                .into_dimensionality::<Ix3>()
                .map_err(|e| anyhow!("Dimensionality: {}", e)).unwrap()
                .to_owned()
        };

        let output_view = output_owned.view();
        self.process_output(&output_view, orig_w, orig_h, scale, pad_x, pad_y)
    }

    fn convert_bbox(
        &self,
        xc: f32,
        yc: f32,
        w: f32,
        h: f32,
        orig_width: f32,
        orig_height: f32,
        scale: f32,
        pad_x: f32,
        pad_y: f32,
    ) -> BoundingBox {
        let x1 = xc - w / 2.0;
        let y1 = yc - h / 2.0;
        let x2 = xc + w / 2.0;
        let y2 = yc + h / 2.0;

        let x1_orig = ((x1 - pad_x) / scale).clamp(0.0, orig_width);
        let y1_orig = ((y1 - pad_y) / scale).clamp(0.0, orig_height);
        let x2_orig = ((x2 - pad_x) / scale).clamp(0.0, orig_width);
        let y2_orig = ((y2 - pad_y) / scale).clamp(0.0, orig_height);

        BoundingBox::new(x1_orig, y1_orig, x2_orig, y2_orig)
    }

    fn non_max_suppression(mut detections: Vec<DetectionResult>, nms_threshold: f32) -> Vec<DetectionResult> {
        detections
            .sort_by(|a, b|
            b.confidence.partial_cmp(&a.confidence).unwrap());

        let mut results = Vec::new();

        while !detections.is_empty() {
            results.push(detections[0].clone());
            detections = detections
                .drain(1..)
                .filter(|d|
                    d.bbox.iou(&results.last().unwrap().bbox) < nms_threshold
                )
                .collect();
        }

        results
    }

    fn process_output(
        &self,
        output: &ArrayView<f32, Ix3>,
        orig_width: f32,
        orig_height: f32,
        scale: f32,
        pad_x: f32,
        pad_y: f32,
    ) -> Result<Vec<DetectionResult>> {
        let mut detections = Vec::new();
        let shape = output.shape();

        if shape[1] == 6 {
            for i in 0..shape[2] {
                let det_vec: Vec<f32> = output
                    .slice(s![0, .., i])
                    .iter()
                    .cloned()
                    .collect();

                let confidence = det_vec[4];
                let class_id = det_vec[5] as usize;
                if confidence < self.confidence_threshold { continue; }

                let label = self.class_labels
                    .get(class_id)
                    .cloned()
                    .unwrap_or_else(|| "unknown".into());

                let bbox = self.convert_bbox(
                    det_vec[0], det_vec[1], det_vec[2], det_vec[3],
                    orig_width, orig_height, scale, pad_x, pad_y,
                );
                detections.push(DetectionResult { bbox, label, confidence });
            }
        } else {
            for i in 0..shape[2] {
                let det_vec: Vec<f32> = output
                    .slice(s![0, .., i])
                    .iter()
                    .cloned()
                    .collect();

                let bbox_raw = &det_vec[0..4];
                let scores = &det_vec[4..];
                let (class_id, confidence) = scores
                    .iter()
                    .enumerate()
                    .max_by(|(_, a), (_, b)| a.partial_cmp(b).unwrap())
                    .unwrap();

                if *confidence < self.confidence_threshold { continue; }

                let label = self.class_labels
                    .get(class_id)
                    .cloned()
                    .unwrap_or_else(|| "unknown".into());

                let bbox = self.convert_bbox(
                    bbox_raw[0], bbox_raw[1], bbox_raw[2], bbox_raw[3],
                    orig_width, orig_height, scale, pad_x, pad_y,
                );
                detections.push(DetectionResult { bbox, label, confidence: *confidence });
            }

        }
        let filtered = Self::non_max_suppression(detections, self.nms_threshold);
        Ok(filtered)
    }
}

