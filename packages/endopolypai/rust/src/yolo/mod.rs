pub mod flutter_yolo;
pub mod endo_yolo;

pub use endo_yolo::*;
pub use flutter_yolo::*;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
//     Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
