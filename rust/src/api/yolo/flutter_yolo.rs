use anyhow::anyhow;
use flutter_rust_bridge::frb;
use image::{DynamicImage, ImageBuffer, RgbaImage};
use ort::error::Result;
use crate::yolo::YOLO;

#[frb]
#[derive(Debug, Clone)]
pub struct FFIDetectionResult {
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32,
    pub label: String,
    pub confidence: f32,
}

#[frb(opaque)]
pub struct YoloHandle(pub YOLO);

#[frb]
pub fn yolo_new(
    model_path: String,
    class_labels: Vec<String>,
    confidence_threshold: f32,
    nms_threshold: f32,
) -> Result<YoloHandle> {
    let yolo = YOLO::new(
        model_path.as_str(),
        class_labels,
        confidence_threshold,
        nms_threshold
    );
    Ok(YoloHandle(yolo.unwrap()))
}

#[frb]
pub fn yolo_predict(
    yolo_handle: &mut YoloHandle,
    width: u32,
    height: u32,
    pixels: Vec<u8>
) -> Result<Vec<FFIDetectionResult>> {
    let buffer = ImageBuffer::from_raw(width, height, pixels)
        .ok_or_else(|| anyhow!("Invalid pixel buffer length")).expect("HOW");
    let img = DynamicImage::ImageRgb8(buffer);
    let yolo = &mut yolo_handle.0;
    let dets = yolo.predict(&img)?;
    let ffi = dets.into_iter()
        .map(|d| FFIDetectionResult{
            x1: d.bbox.x1,
            y1: d.bbox.y1,
            x2: d.bbox.x2,
            y2: d.bbox.y2,
            label: d.label,
            confidence: d.confidence,
        }).collect();
    Ok(ffi)
}

