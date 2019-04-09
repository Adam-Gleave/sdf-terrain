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
        //noise: gfx::TextureSampler<[f32; 4]> = "t_Noise",
        out: gfx::RenderTarget<Srgba8> = "Target0",
    }
}

const BLACK: [f32; 4] = [0.0, 0.0, 0.0, 1.0];
const INDICES: &[u16] = &[0, 1, 2, 2, 3, 0];
const RES: [f32; 2] = [1280.0, 800.0];
const NOISE_TEX_SIZE: usize = 256;

const RECT: &[Vertex] = &[
    Vertex { pos: [1.0, -1.0], colour: BLACK },
    Vertex { pos: [-1.0, -1.0], colour: BLACK },
    Vertex { pos: [-1.0, 1.0], colour: BLACK },
    Vertex { pos: [1.0, 1.0], colour: BLACK },
];

const PERMUTATIONS: [u8; 256] = [
    156, 165, 73, 109, 61, 162, 241, 239, 76, 58, 122, 112, 206, 210, 129, 42, 
    75, 195, 226, 92, 128, 82, 249, 170, 174, 225, 152, 242, 64, 9, 153, 160, 
    236, 77, 163, 150, 126, 142, 202, 48, 101, 81, 91, 145, 50, 124, 36, 117, 
    47, 253, 207, 183, 252, 146, 60, 26, 28, 63, 32, 154, 134, 193, 199, 171, 
    198, 107, 161, 46, 143, 56, 168, 138, 43, 74, 208, 89, 1, 20, 148, 215, 
    135, 17, 45, 155, 100, 247, 224, 95, 219, 7, 121, 10, 177, 37, 62, 214, 
    194, 203, 35, 25, 182, 228, 103, 186, 68, 59, 237, 21, 40, 158, 133, 85, 
    187, 34, 44, 57, 93, 30, 127, 151, 130, 172, 222, 190, 97, 33, 188, 67, 
    31, 157, 13, 41, 6, 175, 230, 137, 131, 5, 213, 54, 246, 78, 18, 102, 19, 
    123, 229, 191, 180, 192, 98, 141, 96, 104, 79, 116, 251, 105, 118, 218, 
    167, 51, 115, 120, 49, 227, 216, 220, 233, 178, 52, 94, 223, 71, 245, 108, 
    90, 243, 147, 72, 80, 169, 185, 209, 15, 139, 99, 204, 23, 29, 140, 173, 
    125, 244, 196, 66, 87, 24, 84, 234, 132, 119, 184, 238, 250, 16, 106, 211, 
    201, 114, 8, 176, 11, 39, 144, 248, 255, 12, 217, 149, 110, 113, 111, 231, 
    53, 2, 181, 3, 235, 14, 55, 136, 232, 200, 83, 205, 221, 70, 197, 38, 189, 
    86, 22, 164, 65, 27, 166, 254, 240, 159, 212, 69, 0, 4, 179, 88,
];

fn hash(n: usize) -> u8 {
    return PERMUTATIONS[(n % 0xFF) as usize];
}

fn generate_texture_point(coord: (usize, usize)) -> u8 {
    let val = hash(coord.0).wrapping_add(coord.1 as u8);
    hash(val as usize)
}

fn generate_texture() -> [[u8; NOISE_TEX_SIZE]; NOISE_TEX_SIZE] {
    let mut texture: [[u8; NOISE_TEX_SIZE]; NOISE_TEX_SIZE] = 
        [[0; NOISE_TEX_SIZE]; NOISE_TEX_SIZE];
    
    for x in 0..NOISE_TEX_SIZE {
        for y in 0..NOISE_TEX_SIZE {
            texture[x][y] = generate_texture_point((x, y));
        }
    }
    texture
}

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

    let texture_sampler = factory.create_sampler_linear();
    let texture = generate_texture();

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
