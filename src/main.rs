use chrono::{self,Timelike};

use minifb::{Key, Scale, ScaleMode, Window, WindowOptions};

const WIDTH: usize = 640;
const HEIGHT: usize = 480;

type Point2D = (i32, i32);

// Triangle coordiantes *must* be presenting clockwise
type Triangle = [Point2D; 3];
type Color = u32;
type Fb = [Color; WIDTH * HEIGHT];

struct Tile {
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    a: [i32; 3],
    b: [i32; 3],
    c: [i32; 3],
}

/* Assume the points are homogeneous */
fn edge_equation(v0: &Point2D, v1: &Point2D) -> [i32; 3] {
    let a = v0.1 - v1.1;
    let b = v1.0 - v0.0;
    let c = -(a * (v0.0 + v1.0) + b * (v0.1 + v1.1) + 1) / 2;

    [a, b, c]
}

fn rasterize_tile(fb: &mut Fb, tile: Tile, color: Color) {
    let mut e0 = [0; 3];
    for i in 0..3 {
        e0[i] = tile.a[i] * tile.x0 + tile.b[i] * tile.y0 + tile.c[i];
    }

    for y in tile.y0..=tile.y1 {
        let mut e = e0;

        for x in tile.x0..=tile.x1 {
            if 0 <= e[0] && 0 <= e[1] && 0 <= e[2] {
                assert!(0 <= y && y < HEIGHT as i32, "({x},{y}) outside screen");
                assert!(0 <= x && x < WIDTH as i32, "({x},{y}) outside screen");
                fb[y as usize * WIDTH + x as usize] = color;
            }
            for i in 0..3 {
                e[i] += tile.a[i];
            }
        }

        for i in 0..3 {
            e0[i] += tile.b[i];
        }
    }
}

fn rasterize_triangle(fb: &mut Fb, v: Triangle, color: Color) {
    let mut a = [0; 3];
    let mut b = [0; 3];
    let mut c = [0; 3];

    let mut x0 = v[0].0;
    let mut x1 = v[0].0;
    let mut y0 = v[0].1;
    let mut y1 = v[0].1;

    for i in 0..3 {
        let edge = edge_equation(&v[i], &v[(i + 1) % 3]);
        a[i] = edge[0];
        b[i] = edge[1];
        c[i] = edge[2];
        x0 = v[i].0.min(x0);
        x1 = v[i].0.max(x1);
        y0 = v[i].1.min(y0);
        y1 = v[i].1.max(y1);
    }

    //println!("({x0},{y0}) - ({x1},{y1})");

    let tile = Tile {
        x0,
        y0,
        x1,
        y1,
        a,
        b,
        c,
    };

    rasterize_tile(fb, tile, color);
}

//                     (20, 0)
//                     #
//                    ###
//                  #######
//                ###########
//               ##############
//             ##################
//           ######################
//          #########################
//        #############################
//      ################################
//    ##(3,10)############################
//            ##############################
//                    ########################
//                            ##################
//                                    ############
//                                            ###### (48, 15)
//

/*
fn lastnonspace(line: &[char]) -> usize {
    let mut last = 0;
    for (i, ch) in line.iter().enumerate() {
        if *ch != ' ' {
            last = i + 1;
        }
    }

    last
}
*/

fn rotate(p: Point2D, origin: Point2D, angle: f32) -> Point2D {
    let (x, y) = (p.0 - origin.0, p.1 - origin.1);
    let (c, s) = (angle.cos(), angle.sin());
    //print!("({},{})={} rotated by {angle} = ({c},{s}) around ({},{}) -> ", x, y, x*x+y*y, origin.0, origin.1);
    let (x, y) = (x as f32 * c - y as f32 * s, y as f32 * c + x as f32 * s);
    //println!("({},{})={}", x, y, x*x+y*y);

    (x as i32 + origin.0, y as i32 + origin.1)
}

fn main() {
    let mut window = Window::new(
        "Display - ESC to exit",
        WIDTH,
        HEIGHT,
        WindowOptions {
            resize: true,
            scale: Scale::X2,
            scale_mode: ScaleMode::AspectRatioStretch,
            ..WindowOptions::default()
        },
    )
    .expect("Unable to Open Window");

    // Limit to max ~60 fps update rate
    window.limit_update_rate(Some(std::time::Duration::from_micros(16600)));
    window.set_background_color(20, 20, 20);
    let mut fb = [0; WIDTH * HEIGHT];

    let center = (WIDTH as i32 / 2, HEIGHT as i32 / 2);
    let hp0 = (center.0, HEIGHT as i32 / 5);
    let mp0 = (center.0, 0);
    let p1 = (center.0 + 20, center.1 + 20);
    let p2 = (center.0 - 20, center.1 + 20);

    //println!("{:?}", chrono::offset::Local::now());

    while window.is_open() && !window.is_key_down(Key::Q) {
	let t = chrono::offset::Local::now();
	let (h, m, s) = (t.hour() % 12, t.minute(), t.second());

        let hour_rad = 3.1415926535 * 2. / 12. * h as f32;
        let minute_rad = 3.1415926535 * 2. / 60. * m as f32;
        let second_rad = 3.1415926535 * 2. / 60. * s as f32;

        rasterize_triangle(
            &mut fb,
            [(center.0, 0),
	     (center.0 + 3, 4),
	     (center.0 - 3, 4)]
                .iter()
                .map(|p| rotate(*p, center, second_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
            0xFFFFFF,
        );

        rasterize_triangle(
            &mut fb,
            [hp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, hour_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
            0xFF0000,
        );

        rasterize_triangle(
            &mut fb,
            [mp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, minute_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
            0xFFFF00,
        );

        window.update_with_buffer(&fb, WIDTH, HEIGHT).unwrap();
	fb = [0; HEIGHT * WIDTH];
    }
}
