use chrono::{self, Timelike};
use minifb::{Key, Scale, ScaleMode, Window, WindowOptions};

type Point2D = (i32, i32);

// Triangle coordiantes *must* be presenting clockwise
type Triangle = [Point2D; 3];
type Color = u32;

const WIDTH: usize = 640;
const HEIGHT: usize = 480;

struct RenderTile {
    a: [i32; 3],
    b: [i32; 3],
    c: [i32; 3],

    e0: [i32; 3],
    e: [i32; 3],
}

fn i18_chk(v: i32) {
    // i16 isn't enough but two more bits would be
    assert!(-32768 * 4 <= v);
    assert!(v < 32768 * 4);
}

fn i18_chk3(v: &[i32; 3]) {
    i18_chk(v[0]);
    i18_chk(v[1]);
    i18_chk(v[2]);
}

impl RenderTile {
    fn new(a: [i32; 3], b: [i32; 3], c: [i32; 3]) -> Self {
        i18_chk3(&a);
        i18_chk3(&b);
        i18_chk3(&c);

        Self {
            a,
            b,
            c,
            e0: c,
            e: c,
        }
    }

    fn start(&mut self) {
        self.e0 = self.c;
        self.e = self.c
    }

    fn stepx(&mut self, pixel: &mut Color, color: Color) {
        if 0 <= self.e[0] && 0 <= self.e[1] && 0 <= self.e[2] {
            *pixel = color;
        }
        for i in 0..3 {
            self.e[i] += self.a[i];
        }
        i18_chk3(&self.e);
    }

    fn stepy(&mut self) {
        for i in 0..3 {
            self.e0[i] += self.b[i];
            self.e = self.e0;
            i18_chk3(&self.e);
        }
    }
}

/* Assume the points are homogeneous */
fn edge_equation(v0: &Point2D, v1: &Point2D) -> [i32; 3] {
    let a = v0.1 - v1.1;
    let b = v1.0 - v0.0;
    let c = -(a * (v0.0 + v1.0) + b * (v0.1 + v1.1)) / 2;

    [a, b, c]
}

// Hack for the RTL implementation; pack three signed 18-bit values into a number
fn pack(v: [i32; 3]) -> u64 {
    v[0] as u64 & 0x3FFFF | (v[1] as u64 & 0x3FFFF) << 18 | (v[2] as u64 & 0x3FFFF) << 36
}

// cfg(test) something
fn unpack(v: u64) -> [i32; 3] {
    [
        (v << 14) as i32 >> 14,
        (v >> 18 << 14) as i32 >> 14,
        (v >> 36 << 14) as i32 >> 14,
    ]
}

fn check(v0: i32, v1: i32, v2: i32) {
    let w = unpack(pack([v0, v1, v2]));
    assert_eq!(w[0], v0);
    assert_eq!(w[1], v1);
    assert_eq!(w[2], v2);
}

#[test]
fn test_pack() {
    check(0, 0, 0);
    check(1, 2, 3);
    check(-1, -2, -3);
    check(-1, -2, 3);
    check(-1, 2, -3);
    check(1, -2, -3);
    check(1729, 666, -42);
}

fn triangle_edges(v: Triangle) -> ([i32; 3], [i32; 3], [i32; 3]) {
    let mut a = [0; 3];
    let mut b = [0; 3];
    let mut c = [0; 3];

    for i in 0..3 {
        let edge = edge_equation(&v[i], &v[(i + 1) % 3]);
        a[i] = edge[0];
        b[i] = edge[1];
        c[i] = edge[2];
    }

    (a, b, c)
}

fn rasterize_triangle(v: Triangle) -> RenderTile {
    let (a, b, c) = triangle_edges(v);

    RenderTile::new(a, b, c)
}

fn rotate(p: Point2D, origin: Point2D, angle: f32) -> Point2D {
    let (x, y) = (p.0 - origin.0, p.1 - origin.1);
    let (c, s) = (angle.cos(), angle.sin());
    //print!("({},{})={} rotated by {angle} = ({c},{s}) around ({},{}) -> ", x, y, x*x+y*y, origin.0, origin.1);
    let (x, y) = (x as f32 * c - y as f32 * s, y as f32 * c + x as f32 * s);
    //println!("({},{})={}", x, y, x*x+y*y);

    (x as i32 + origin.0, y as i32 + origin.1)
}

#[test]
fn calculate_second_edges() {
    let center = (WIDTH as i32 / 2, HEIGHT as i32 / 2);
    let hp0 = (center.0, HEIGHT as i32 / 5);
    let mp0 = (center.0, 3);
    let p1 = (center.0 + 20, center.1 + 20);
    let p2 = (center.0 - 20, center.1 + 20);

    println!("         case (second)");
    for s in 0..60 {
        let second_rad = std::f32::consts::PI * 2. / 60. * s as f32;

        let (a, b, c) = triangle_edges(
            [
                (center.0, 3),
                (center.0 + 3, center.1 - 3),
                (center.0 - 3, center.1 - 3),
            ]
            .iter()
            .map(|p| rotate(*p, center, second_rad))
            .collect::<Vec<_>>()
            .try_into()
            .unwrap(),
        );
        println!("          {s}: {{sec_a, sec_b, sec_c}} <= {{54'h{:x}, 54'h{:x}, 54'h{:x}}};",
                 pack(a), pack(b), pack(c));
    }
    println!("         endcase");

    println!("         case (minute)");
    for m in 0..60 {
        let minute_rad = std::f32::consts::PI * 2. / 60. * m as f32;
        let (a, b, c) = triangle_edges(
            [mp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, minute_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
        );
        println!("         {m}: {{min_a, min_b, min_c}} <= {{54'h{:x}, 54'h{:x}, 54'h{:x}}};",
                 pack(a), pack(b), pack(c));
    }
    println!("         endcase");

    println!("         case (hour)");
    for h in 0..60 {
        let hour_rad = std::f32::consts::PI * 2. / 12. * h as f32;
        let (a, b, c) = triangle_edges(
            [hp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, hour_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
        );
        println!("         {h}: {{hour_a, hour_b, hour_c}} <= {{54'h{:x}, 54'h{:x}, 54'h{:x}}};",
                 pack(a), pack(b), pack(c));
    }
    println!("         endcase");
}

fn main() {
    let mut window = Window::new(
        "Watch - 'q' to exit",
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
    let mp0 = (center.0, 3);
    let p1 = (center.0 + 20, center.1 + 20);
    let p2 = (center.0 - 20, center.1 + 20);

    while window.is_open() && !window.is_key_down(Key::Q) {
        let t = chrono::offset::Local::now();
        let (h, m, s) = (t.hour() % 12, t.minute(), t.second());

        let hour_rad = std::f32::consts::PI * 2. / 12. * h as f32;
        let minute_rad = std::f32::consts::PI * 2. / 60. * m as f32;
        let second_rad = std::f32::consts::PI * 2. / 60. * s as f32;

        let mut hour_tile = rasterize_triangle(
            [hp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, hour_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
        );

        let mut minute_tile = rasterize_triangle(
            [mp0, p1, p2]
                .iter()
                .map(|p| rotate(*p, center, minute_rad))
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
        );

        let mut second_tile = rasterize_triangle(
            [
                (center.0, 3),
                (center.0 + 3, center.1 - 3),
                (center.0 - 3, center.1 - 3),
            ]
            .iter()
            .map(|p| rotate(*p, center, second_rad))
            .collect::<Vec<_>>()
            .try_into()
            .unwrap(),
        );

        hour_tile.start();
        minute_tile.start();
        second_tile.start();

        for y in 0..HEIGHT {
            for x in 0..WIDTH {
                let pixel = &mut fb[x + y * WIDTH];
                hour_tile.stepx(pixel, 0xFF0000);
                minute_tile.stepx(pixel, 0xFFFF00);
                second_tile.stepx(pixel, 0xFFFFFF);
            }
            hour_tile.stepy();
            minute_tile.stepy();
            second_tile.stepy();
        }

	fb[center.0 as usize] = 0xFFFFFF;	// center top
	fb[center.1 as usize * WIDTH + center.0 as usize] = 0xFFFFFF; // center
	fb[center.1 as usize * WIDTH +  80] = 0xFFFFFF; // center left
	fb[center.1 as usize * WIDTH + 560] = 0xFFFFFF; // center right
	fb[479 as usize * WIDTH + center.0 as usize] = 0xFFFFFF; // center bot

	// 1 O'clock = 30gr = (240/2, 240 * sqrt(3)/2) = (120,208)
	fb[center.0 as usize + 120 + (center.1 as usize + 208) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize - 120 + (center.1 as usize + 208) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize + 120 + (center.1 as usize - 208) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize - 120 + (center.1 as usize - 208) * WIDTH] = 0xFFFFFF; // 1

	fb[center.0 as usize + 208 + (center.1 as usize + 120) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize - 208 + (center.1 as usize + 120) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize + 208 + (center.1 as usize - 120) * WIDTH] = 0xFFFFFF; // 1
	fb[center.0 as usize - 208 + (center.1 as usize - 120) * WIDTH] = 0xFFFFFF; // 1

        window.update_with_buffer(&fb, WIDTH, HEIGHT).unwrap();
        fb = [0; HEIGHT * WIDTH];
    }
}
