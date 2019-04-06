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
    }

    constant Uniforms {
        resolution: [f32; 2] = "u_Resolution",
    }

    pipeline pipe {
        vbuf: gfx::VertexBuffer<Vertex> = (),
        consts: gfx::ConstantBuffer<Uniforms> = "consts",
        out: gfx::RenderTarget<Srgba8> = "Target0",
    }
}

const BLACK: [f32; 4] = [0.0, 0.0, 0.0, 1.0];
const INDICES: &[u16] = &[0, 1, 2, 2, 3, 0];
const RES: [f32; 2] = [1280.0, 800.0];

const RECT: &[Vertex] = &[
    Vertex { pos: [1.0, -1.0], colour: BLACK },
    Vertex { pos: [-1.0, -1.0], colour: BLACK },
    Vertex { pos: [-1.0, 1.0], colour: BLACK },
    Vertex { pos: [1.0, 1.0], colour: BLACK },
];

fn update_uniforms(window: &glutin::WindowedContext) -> Uniforms {
    let res = if let Some(dimensions) = window.window().get_inner_size() {
        [dimensions.width as f32, dimensions.height as f32]
    } else {
        RES
    };

    Uniforms {            
        resolution: res,
    }
}

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
        consts: factory.create_constant_buffer(1),
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
        let consts = update_uniforms(&window);

        encoder.clear(&data.out, BLACK);
        encoder.update_constant_buffer(&data.consts, &consts);
        encoder.draw(&slice, &pso, &data);
        encoder.flush(&mut device);
        window.swap_buffers().unwrap();
        device.cleanup();
    }
}
