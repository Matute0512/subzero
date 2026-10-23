import os
import struct
import zlib
import math

def create_png(width, height, get_pixel_fn, filename):
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # filter type 0 (None)
        for x in range(width):
            r, g, b, a = get_pixel_fn(x, y, width, height)
            raw_data.extend([r, g, b, a])
    
    compressed = zlib.compress(bytes(raw_data), level=9)
    
    def chunk(tag, data):
        length = len(data)
        crc = zlib.crc32(tag + data) & 0xffffffff
        return struct.pack(">I", length) + tag + data + struct.pack(">I", crc)
    
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr_data)
    png += chunk(b"IDAT", compressed)
    png += chunk(b"IEND", b"")
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "wb") as f:
        f.write(png)
    print(f"Generated {filename} ({width}x{height})")

def point_to_segment_dist(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    l2 = dx*dx + dy*dy
    if l2 == 0:
        return math.hypot(px - x1, py - y1)
    t = max(0, min(1, ((px - x1)*dx + (py - y1)*dy) / l2))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.hypot(px - proj_x, py - proj_y)

def draw_snowflake(x, y, w, h, transparent_bg=False, scale=1.0):
    cx, cy = w / 2.0, h / 2.0
    
    # Base background: #0A192F (10, 25, 47)
    if transparent_bg:
        bg = (0, 0, 0, 0)
    else:
        bg = (10, 25, 47, 255)
        
    # Snowflake coordinates relative to center
    dx = x - cx
    dy = y - cy
    dist = math.hypot(dx, dy)
    
    # Primary color: #0077B6 (0, 119, 182)
    # Secondary highlight: #48CAE4 (72, 202, 228)
    # Ice white glow: #CAF0F8 (202, 240, 248)
    
    size = min(w, h) * 0.38 * scale
    
    # Check 6 branches of snowflake
    # Rotate (dx, dy) to 60-degree sector
    angle = math.atan2(dy, dx)
    angle_norm = (angle % (math.pi / 3)) - (math.pi / 6) # [-pi/6, pi/6]
    rot_x = dist * math.cos(angle_norm)
    rot_y = dist * math.sin(angle_norm)
    
    # Center crystal (hexagon)
    r_hex = size * 0.22
    in_center = rot_x <= r_hex * math.cos(math.pi / 6) and (rot_x * 0.5 + abs(rot_y) * math.sin(math.pi / 3)) <= r_hex * math.cos(math.pi / 6)
    
    # Main spine from 0 to size
    d_main = point_to_segment_dist(rot_x, abs(rot_y), 0, 0, size, 0)
    
    # Sub-branch 1
    b1_start = size * 0.45
    b1_len = size * 0.28
    b1_ang = math.pi / 3
    x_b1_end = b1_start + b1_len * math.cos(b1_ang)
    y_b1_end = b1_len * math.sin(b1_ang)
    d_b1 = point_to_segment_dist(rot_x, abs(rot_y), b1_start, 0, x_b1_end, y_b1_end)
    
    # Sub-branch 2
    b2_start = size * 0.72
    b2_len = size * 0.22
    b2_ang = math.pi / 3
    x_b2_end = b2_start + b2_len * math.cos(b2_ang)
    y_b2_end = b2_len * math.sin(b2_ang)
    d_b2 = point_to_segment_dist(rot_x, abs(rot_y), b2_start, 0, x_b2_end, y_b2_end)
    
    # Sub-branch tip arrowhead
    tip_start = size * 0.90
    tip_len = size * 0.12
    tip_ang = math.pi / 3
    x_tip_end = tip_start - tip_len * math.cos(tip_ang)
    y_tip_end = tip_len * math.sin(tip_ang)
    d_tip = point_to_segment_dist(rot_x, abs(rot_y), size, 0, x_tip_end, y_tip_end)

    min_line_d = min(d_main, d_b1, d_b2, d_tip)
    thickness = max(2.5, size * 0.045)
    
    if in_center:
        # Subtle gradient inside center diamond
        center_inner = rot_x <= (r_hex*0.6) * math.cos(math.pi / 6) and (rot_x * 0.5 + abs(rot_y) * math.sin(math.pi / 3)) <= (r_hex*0.6) * math.cos(math.pi / 6)
        if center_inner:
            return (144, 224, 239, 255) # Light ice blue
        return (0, 119, 182, 255) # #0077B6
        
    if min_line_d <= thickness:
        # Core line
        core_thickness = thickness * 0.4
        if min_line_d <= core_thickness:
            return (72, 202, 228, 255) # Ice accent #48CAE4
        return (0, 119, 182, 255) # Primary #0077B6
        
    # Anti-aliasing edge
    if min_line_d <= thickness + 1.5:
        alpha = max(0.0, 1.0 - (min_line_d - thickness) / 1.5)
        if transparent_bg:
            return (0, 119, 182, int(255 * alpha))
        else:
            r = int(bg[0] * (1 - alpha) + 0 * alpha)
            g = int(bg[1] * (1 - alpha) + 119 * alpha)
            b = int(bg[2] * (1 - alpha) + 182 * alpha)
            return (r, g, b, 255)

    return bg

if __name__ == "__main__":
    out_dir = r"d:\Dev\Portafolio\Dart\subzero\assets\icons"
    # App icon (solid background #0A192F with #0077B6 snowflake)
    create_png(512, 512, lambda x, y, w, h: draw_snowflake(x, y, w, h, transparent_bg=False, scale=0.9), os.path.join(out_dir, "app_icon.png"))
    
    # Foreground adaptive icon (transparent background, scale 0.65 for Android adaptive icon safe zone)
    create_png(512, 512, lambda x, y, w, h: draw_snowflake(x, y, w, h, transparent_bg=True, scale=0.65), os.path.join(out_dir, "app_icon_foreground.png"))
    
    # Splash logo (transparent background)
    create_png(512, 512, lambda x, y, w, h: draw_snowflake(x, y, w, h, transparent_bg=True, scale=0.85), os.path.join(out_dir, "splash_logo.png"))

