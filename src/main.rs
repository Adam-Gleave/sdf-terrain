#[macro_use]
extern crate gfx;

extern crate glutin;
extern crate gfx_window_glutin;

use gfx::Device;
use gfx_window_glutin as gfx_glutin;

use gfx::format::{DepthStencil, Srgba8};
use gfx::traits::FactoryExt;

gfx_defines! {
    vertex Vertex {
        pos: [f32; 2] = "a_Pos",
        colour: [f32; 4] = "a_Colour",
        res: [f32; 2] = "vert_Resolution",
    }

    pipeline pipe {
        vbuf: gfx::VertexBuffer<Vertex> = (),
        out: gfx::RenderTarget<Srgba8> = "Target0",
    }
}

const BLACK: [f32; 4] = [0.0, 0.0, 0.0, 1.0];
const WHITE: [f32; 4] = [1.0, 1.0, 1.0, 1.0];
const RES: [f32; 2] = [1280.0, 800.0];

const RECT: &[Vertex] = &[
    Vertex { pos: [1.0, -1.0], colour: WHITE, res: RES },
    Vertex { pos: [-1.0, -1.0], colour: WHITE, res: RES },
    Vertex { pos: [-1.0, 1.0], colour: WHITE, res: RES },
    Vertex { pos: [1.0, 1.0], colour: WHITE, res: RES },
];

const INDICES: &[u16] = &[0, 1, 2, 2, 3, 0];

fn main() {
    let mut events_loop = glutin::EventsLoop::new();
    let builder = glutin::WindowBuilder::new()
        .with_title("SDF")
        .with_dimensions(glutin::dpi::LogicalSize::new(1280.0, 800.0));
    let context = glutin::ContextBuilder::new();

    let (window, mut device, mut factory, rtv, mut dtv) = 
        gfx_window_glutin::init::<Srgba8, DepthStencil>(builder, context, &events_loop)
            .expect("Failed to create window");

    let mut encoder: gfx::Encoder<_, _> = factory.create_command_buffer().into();

    let pso = factory.create_pipeline_simple(
        include_bytes!(concat!(env!("CARGO_MANIFEST_DIR"), "/shaders/vert.glsl")),
        include_bytes!(concat!(env!("CARGO_MANIFEST_DIR"), "/shaders/frag.glsl")),
        pipe::new(),
    ).expect("Failed to create pipeline");

    let (vertex_buffer, slice) = 
        factory.create_vertex_buffer_with_slice(RECT, INDICES);

    let mut data = pipe::Data {
        vbuf: vertex_buffer,
        out: rtv,
    };

    let mut running = true;
    while running {
        events_loop.poll_events(|event| {
            use glutin::WindowEvent::*;
            use glutin::VirtualKeyCode::*;
            match event {
                glutin::Event::WindowEvent{event, ..} => match event {
                    KeyboardInput{device_id: _, input} => match input.virtual_keycode {
                        Some(Escape) => running = false,
                        _ => (),   
                    },
                    CloseRequested => running = false,
                    Resized(_) => {
                        gfx_glutin::update_views(&window, &mut data.out, &mut dtv);
                    },
                    _ => (),
                },
                _ => (),
            }
        });

        encoder.clear(&data.out, BLACK);
        encoder.draw(&slice, &pso, &data);
        encoder.flush(&mut device);
        window.swap_buffers().unwrap();
        device.cleanup();
    }
}
