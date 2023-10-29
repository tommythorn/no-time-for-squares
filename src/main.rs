const HEIGHT: usize = 1200;
const WIDTH: usize = 1200;

type Point2D = (i32, i32);

// Triangle coordiantes *must* be presenting clockwise
type Triangle = [Point2D; 3];
type Color = char;
type Fb = [[Color; WIDTH]; HEIGHT];

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
    let c = -(a * (v0.0 + v1.0) + b * (v0.1 + v1.1)) / 2;

    [a, b, c]
}

fn rasterize_tile(fb: &mut Fb, tile: Tile, color: Color) {
    let mut e0 = [0; 3];
    for i in 0..3 {
        e0[i] = tile.a[i] * tile.x0 + tile.b[i] * tile.y0 + tile.c[i];
    }

    for y in tile.y0..tile.y1 {
        let mut e = e0;

        for x in tile.x0..tile.x1 {
            if 0 <= e[0] && 0 <= e[1] && 0 <= e[2] {
                fb[y as usize][x as usize] = color;
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

    println!("({x0},{y0}) - ({x1},{y1})");

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

fn lastnonspace(line: &[char]) -> usize {
    let mut last = 0;
    for (i, ch) in line.iter().enumerate() {
        if *ch != ' ' {
            last = i + 1;
        }
    }

    last
}

fn main() {
    let mut fb = [[' '; WIDTH]; HEIGHT];

    rasterize_triangle(&mut fb, [(20, 0), (50, 16), (3, 10)], '#');
    rasterize_triangle(&mut fb, [(1, 3), (41, 3), (48, 9)], '*');
    rasterize_triangle(&mut fb, [(0, 0), (50, 20), (45, 20)], '.');

    rasterize_triangle(&mut fb, [(30, 20), (60, 20), (60, 40)], '1');
    rasterize_triangle(&mut fb, [(30, 20), (60, 40), (30, 40)], '2');


    for y in 0..=40 {
        for x in 0..lastnonspace(&fb[y]) {
            print!("{}", fb[y][x]);
        }

        println!();
    }
}
