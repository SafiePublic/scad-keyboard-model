// https://github.com/BelfrySCAD/BOSL2
include <../BOSL2/std.scad>

$fn = $preview ? 24 : 64;
$ns = 0.8;

// Switch dimensions
$sw_length = 13.6;
$sw_width = 14.2;
$sw_groove = calcHeight(1);

// ------------------------- //

KEY_PITCH = calcWidth(5);
KEY_ROWS = [11, 11, 11, 11];
KEY_COLS = len(KEY_ROWS);

CASE_PADDING_X = calcWidth(4);
CASE_PADDING_Y = calcWidth(4);

CASE_CORNER_RAD = 2;

// calculate the keyboard dimensions
CASE_WIDTH = (max(KEY_ROWS) * $sw_width)
				+ ((max(KEY_ROWS)-1) * KEY_PITCH) + (CASE_PADDING_X * 2);
CASE_LENGTH = (KEY_COLS * $sw_length)
				+ ((KEY_COLS - 1) *KEY_PITCH) + (CASE_PADDING_Y * 2);

CASE_PLATE_THICKNESS = calcHeight(3);
CASE_INNER_HEIGHT = calcHeight(12);

echo("CASE_WIDTH: ", CASE_WIDTH);
echo("CASE_LENGTH: ", CASE_LENGTH);
echo("CASE_HEIGHT: ", CASE_INNER_HEIGHT+CASE_PLATE_THICKNESS);

// ------------------------------------------------------ //

render() {
	CaseTop();
	down(10) PicoHolder();
	down(20) CaseLid();
}

// ------------------------------------------------------ //

BACK_PLATE_MOUNT_POSITION = positions([
	[1, 2], [1, 4], [1, 7], [1, 9],
	[3, 2], [3, 4], [3, 7], [3, 9],
]);

PICO_MOUNT_POSITION = positions([
	[1, 5], [1, 6],
	[2, 5], [2, 6],
]);

CENTER_X = ((($sw_width + KEY_PITCH) *  max(KEY_ROWS)) - KEY_PITCH) / -2;
CENTER_Y = ((($sw_length + KEY_PITCH) * KEY_COLS) - KEY_PITCH) / -2;

module CaseTop() {
	// top plate
	difference() {
		cuboid([CASE_WIDTH, CASE_LENGTH, CASE_PLATE_THICKNESS],
			rounding=CASE_CORNER_RAD,
			anchor=BOTTOM,
			edges=[FRONT+RIGHT, FRONT+LEFT, BACK+RIGHT, BACK+LEFT]
		);

		move([$sw_width/2 + CENTER_X, $sw_length/2 + CENTER_Y, CASE_PLATE_THICKNESS])
			KeyHoles();
	}

	// wall
	difference() {
		rect_tube(size=[CASE_WIDTH, CASE_LENGTH],
			wall=calcWidth(3),
			h=CASE_INNER_HEIGHT,
			rounding=CASE_CORNER_RAD,
			anchor=TOP
		);
		move([0, -CASE_LENGTH/2])
			cuboid([12,20,20], rounding=5, anchor=TOP);
	}

	// mounts
	difference() {
		yrot(180)
		union() {
			// mount for back plate	
			CaseMount(BACK_PLATE_MOUNT_POSITION, CASE_INNER_HEIGHT);
			// mount for pico
			CaseMount(PICO_MOUNT_POSITION, calcHeight(2));
		}		
		scale([1, 1, 20])
			move([$sw_width/2 + CENTER_X, $sw_length/2 + CENTER_Y, CASE_PLATE_THICKNESS])
				KeyHoles();
	}
}

module CaseLid() {
	difference() {
		cuboid([CASE_WIDTH, CASE_LENGTH, CASE_PLATE_THICKNESS],
			rounding=CASE_CORNER_RAD,
			anchor=BOTTOM,
			edges=[FRONT+RIGHT, FRONT+LEFT, BACK+RIGHT, BACK+LEFT]
		);

		for (pos = BACK_PLATE_MOUNT_POSITION)
			move([pos[0], pos[1]]) up(CASE_PLATE_THICKNESS)
				BoltHole(h=CASE_PLATE_THICKNESS, withHead=true);
	}
}

module CaseMount(poss, height) {
	for (pos = poss)
		move([pos[0], pos[1]])
			InsertNutHole(mh=height, mt=2);
}

module PicoHolder() {
	MCUWidth = 21;
	MCULength = 51;

	height = calcHeight(2.5);

	difference() {
		cuboid([MCUWidth+4, MCULength+3, height],
			rounding = 2,
			edges = [FRONT+RIGHT, FRONT+LEFT, BACK+RIGHT, BACK+LEFT],
			anchor = BOTTOM
		);

		for (pos = PICO_MOUNT_POSITION)
			move([pos[0], pos[1] + 8]) up(height)
				BoltHole(h=height, withHead=true);
		RaspberryPiPicoMountingHole();
	}

	up(height - 0.01)
		RaspberryPiPicoMountingHole(mt=1, mh=calcHeight(1));
}

module KeyHoles() {
    for (i = [0 : KEY_COLS - 1]) {
        total_switch = KEY_ROWS[i];
        row_CENTER_X = (max(KEY_ROWS) - total_switch) * ($sw_width + KEY_PITCH) / 2;
        row_CENTER_Y = i * ($sw_length + KEY_PITCH);

        for (i = [0 : total_switch - 1]) {
            translate([i * ($sw_width + KEY_PITCH) + row_CENTER_X, row_CENTER_Y, 0]) {
				color("blue")
                Key();
            }  
        }
    }
}

module Key() {
    cube([$sw_width, $sw_length, $sw_groove], anchor=TOP);
    down($sw_groove)
		cube([$sw_width + 2, $sw_length, CASE_PLATE_THICKNESS], anchor=TOP);
}

// ------------------------------------------------------ //

function positions(poss=[[1, 1]]) = [
	for (pos = poss)
		[
			((pos[1]) * $sw_width) + ((pos[1] - 1) * KEY_PITCH) + (KEY_PITCH/2) + CASE_PADDING_X - CASE_WIDTH/2,
			((pos[0]) * $sw_length) + ((pos[0] - 1) * KEY_PITCH) + (KEY_PITCH/2) + CASE_PADDING_X - CASE_LENGTH/2
		]
];

// ------------------------------------------------------ //

function firstLayerPitch() = lookup($ns, [
    [0.4, 0.27],
    [0.8, 0.64]
]);

function layerPitch() = lookup($ns, [
    [0.4, 0.2],
    [0.8, 0.6]
]);

function extrusionWidth() = lookup($ns, [
    [0.4, 0.38],
    [0.8, 0.85]
]);

function calcHeight(height) = 
    ceil(height / layerPitch()) * layerPitch();

function calcWidth(width) = 
    ceil(width / extrusionWidth()) * extrusionWidth();

module BoltHole(bolt=2, h=10, withHead=false, hh=0, mt=0, mh=0, reverse=false) {
    isOnlyHole = mt == 0 && mh == 0;
    height = calcHeight(h);
    dia = lookup(bolt, [
        [2, 2],
        [2.5, 2.5],
        [3, 3],
        [4, 4],
        [5, 5],
    ]) + 0.5;

    if(isOnlyHole) {
        if(withHead) {
            headDia = lookup(bolt, [
                [2, 3.5],
                [3, 5.5],
                [4, 7],
                [5, 9],
            ]) + 0.5;
            headHeight = hh ? calcHeight(hh) : calcHeight(lookup(bolt, [
                [2, 1.3],
                [3, 2],
                [4, 2.6],
                [5, 3.3],
            ])) + 0.5;

            anchor = reverse ? BOTTOM : TOP;
            cylinder(h=h, r=dia/2, anchor=anchor);

            if(reverse) {
                cylinder(h=headHeight, r=headDia/2, anchor=BOTTOM);
            } else {
                cylinder(h=headHeight, r=headDia/2, anchor=TOP);
            }
        }
    } else {
        mountHeight = calcHeight(mh);
        mountThickness = calcWidth(mt);
        difference() {
            cylinder(mountHeight, r=mountThickness+dia/2, anchor=BOTTOM);
            up(mountHeight)
                cylinder(h=height, r=dia/2, anchor=TOP);

            if(withHead) {
                headDia = lookup(bolt, [
                    [2, 3.5],
                    [3, 5.5],
                    [4, 7],
                    [5, 9],
                ]) + 0.5;
                headHeight = calcHeight(lookup(bolt, [
                    [2, 1.3],
                    [3, 2],
                    [4, 2.6],
                    [5, 3.3],
                ])) + 0.5;
                up(height-headHeight)
                    cylinder(h=headHeight, r=headDia/2, anchor=BOTTOM);
            }
        }
    }
}

module InsertNutHole(
    bolt=2,
    h=3.5,
    mt=0,
    mh=0,
    ) {
    // TODO: エラーを書く
    //TODO: mt, mh のいずれかしか指定がない場合にエラーを出す

    isOnlyHole = mt == 0 && mh == 0;
    rad = (lookup(bolt, [
        [2, 3.2],
        [2.5, 4.2],
    ]) + 0.5) / 2;

    if (isOnlyHole) {
        cylinder(h, r=rad, anchor=BOTTOM);
    } else {
        mountHeight = calcHeight(mh);
        mountThickness = calcWidth(mt);
        difference() {
            cylinder(mountHeight, r=mountThickness+rad, anchor=BOTTOM);
            up(mountHeight)
                cylinder(h, r=rad, anchor=TOP);
        }
    }
}

module MagnetHole(mt=0, mh=0, reverse=false) {
    isOnlyHole = mt == 0 && mh == 0;
    //TODO: mt, mh のいずれかしか指定がない場合にエラーを出す
    holeRad = 6/2;
    holeHeight = calcHeight(2);

    if (isOnlyHole) {
        cylinder(h=holeHeight, r=holeRad, anchor=BOTTOM);
    } else {
        mountHeight = calcHeight(mh);
        mountThickness = calcWidth(mt);
        difference() {
            anchor = reverse ? BOTTOM : TOP;
            cylinder(mountHeight, r=mountThickness+holeRad, anchor=BOTTOM);

            if(reverse) {
                cylinder(h=holeHeight, r=holeRad, anchor=anchor);
            } else {
                up(mountHeight)
                cylinder(h=holeHeight, r=holeRad, anchor=anchor);              
            }
        }
    }
}

module RaspberryPiPicoMountingHole(mt=0, mh=0) {
    isOnlyHole = mt == 0 && mh == 0;
    //TODO: mt, mh のいずれかしか指定がない場合にエラーを出す
    ycopies(47, n=2) xcopies(11.4)
        if (isOnlyHole) {
            InsertNutHole();
        } else {
            InsertNutHole(mt=mt, mh=mh);
        }
}