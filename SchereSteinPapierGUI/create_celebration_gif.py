from PIL import Image, ImageDraw
import random
import math

# Settings
WIDTH = 700
HEIGHT = 750
FPS = 25
DURATION_SEC = 15
FRAMES = FPS * DURATION_SEC
FRAME_DELAY_MS = int(1000 / FPS)

random.seed(42)

# Helper color palette
PALETTE = [(0xFF, 0x6B, 0x6B), (0x4E, 0xCD, 0xC4), (0xFF, 0xE6, 0x6D), (0xFF,
                                                                        0x8A, 0x65), (0xAE, 0x73, 0xDC), (0xFF, 0x14, 0x93), (0x00, 0xCE, 0xD1)]


class Confetti:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.vx = (random.random() - 0.5) * 30
        self.vy = - (12 + random.random() * 24)
        self.color = random.choice(PALETTE)
        base_ticks = int((5000) / (1000/FPS))
        self.maxlife = max(10, base_ticks + random.randint(-20, 20))
        self.life = self.maxlife
        self.size = random.randint(18, 32)

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vy += 0.12
        self.life -= 1

    def alive(self):
        return self.life > 0


class Spark:
    def __init__(self, x, y, vx, vy, life, color):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.life = life
        self.maxlife = life
        self.color = color

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vy += 0.12
        self.vx *= 0.995
        self.vy *= 0.998
        self.life -= 1

    def alive(self):
        return self.life > 0


class Firework:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.vy = - (8 + random.random()*6)
        self.color = random.choice(PALETTE)
        self.exploded = False
        self.sparks = []

    def update(self):
        if not self.exploded:
            self.y += self.vy
            self.vy += 0.18
            if self.vy >= 0 or self.y < HEIGHT*0.25:
                self.explode()
        else:
            for s in self.sparks:
                s.update()
            self.sparks = [s for s in self.sparks if s.alive()]

    def explode(self):
        self.exploded = True
        count = random.randint(18, 54)
        base = 3.0 + random.random()*4.0
        for i in range(count):
            angle = random.random() * 2*math.pi
            speed = base*(0.6 + random.random()*1.4)
            vx = math.cos(angle)*speed
            vy = math.sin(angle)*speed - 1.0
            life = random.randint(20, 80)
            c = (
                min(255, self.color[0]+random.randint(-30, 30)),
                min(255, self.color[1]+random.randint(-30, 30)),
                min(255, self.color[2]+random.randint(-30, 30))
            )
            self.sparks.append(Spark(self.x, self.y, vx, vy, life, c))

    def finished(self):
        return self.exploded and len(self.sparks) == 0


# Initialize lists
confetti = []
fireworks = []

# Spawn initial confetti across top area
for i in range(700):
    x = random.random() * WIDTH
    y = random.random() * HEIGHT * 0.6
    confetti.append(Confetti(x, y))

# Spawn initial rockets near bottom
for r in range(10):
    rx = random.random() * WIDTH
    ry = HEIGHT * 0.9
    fireworks.append(Firework(rx, ry))

frames = []

for f in range(FRAMES):
    # occasional new rockets
    if random.random() < 0.12:
        fireworks.append(Firework(random.random()*WIDTH, HEIGHT*0.9))
    # update
    for c in confetti:
        c.update()
    confetti = [c for c in confetti if c.alive()]
    # occasionally add more confetti to keep density
    if len(confetti) < 700 and random.random() < 0.2:
        for i in range(50):
            confetti.append(Confetti(random.random()*WIDTH,
                            random.random()*HEIGHT*0.6))

    for fw in fireworks:
        fw.update()
    fireworks = [fw for fw in fireworks if not fw.finished()]

    # render
    img = Image.new('RGBA', (WIDTH, HEIGHT), (10, 10, 10, 255))
    draw = ImageDraw.Draw(img, 'RGBA')

    # draw confetti
    for c in confetti:
        ratio = max(0.0, min(1.0, c.life / c.maxlife))
        alpha = int(255*ratio)
        col = (c.color[0], c.color[1], c.color[2], alpha)
        bbox = [int(c.x), int(c.y), int(c.x+c.size), int(c.y+c.size)]
        draw.ellipse(bbox, fill=col)

    # draw fireworks (sparks and rockets)
    for fw in fireworks:
        if not fw.exploded:
            # rocket
            draw.ellipse((int(fw.x)-3, int(fw.y)-3, int(fw.x)+3, int(fw.y)+3),
                         fill=(fw.color[0], fw.color[1], fw.color[2], 255))
        else:
            for s in fw.sparks:
                ratio = max(0.0, min(1.0, s.life / s.maxlife))
                alpha = int(255*ratio)
                col = (s.color[0], s.color[1], s.color[2], alpha)
                ss = max(1, int(3*ratio)+1)
                draw.ellipse((int(s.x)-ss, int(s.y)-ss,
                             int(s.x)+ss, int(s.y)+ss), fill=col)

    # convert to palette-based image to reduce size
    frames.append(img.convert('P', palette=Image.ADAPTIVE))

    if f % 50 == 0:
        print(f"Rendered frame {f}/{FRAMES}")

# save GIF
out_path = 'celebration.gif'
frames[0].save(out_path, save_all=True, append_images=frames[1:],
               duration=FRAME_DELAY_MS, loop=0, optimize=False)
print('Saved', out_path)
