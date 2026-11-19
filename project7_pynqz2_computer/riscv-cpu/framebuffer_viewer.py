
import os
import pygame
import numpy as np

WIDTH = 320
HEIGHT = 240
SCALE = 2

FRAME_SIZE = WIDTH * HEIGHT
STREAM_FILE = "framebuffer_stream.rgb332"

pygame.init()

screen = pygame.display.set_mode(
    (WIDTH * SCALE, HEIGHT * SCALE)
)

pygame.display.set_caption("My RISC-V Computer")

clock = pygame.time.Clock()

# Current displayed image
last_frame = np.zeros(
    (HEIGHT, WIDTH, 3),
    dtype=np.uint8
)

# Incomplete bytes from the previous read
pending = bytearray()

running = True

print("Waiting for Verilog framebuffer stream...")

while running and not os.path.exists(STREAM_FILE):
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    clock.tick(30)

if running:
    with open(STREAM_FILE, "rb") as stream:

        print("Connected to RISC-V framebuffer!")

        while running:

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False

            # Read all currently available bytes
            chunk = stream.read()

            if chunk:
                pending.extend(chunk)

                # Number of complete frames available
                complete_frames = len(pending) // FRAME_SIZE

                if complete_frames > 0:

                    # Keep only the newest complete frame
                    latest_start = (
                        complete_frames - 1
                    ) * FRAME_SIZE

                    raw_bytes = pending[
                        latest_start:
                        latest_start + FRAME_SIZE
                    ]

                    # Preserve any incomplete trailing frame
                    remainder = pending[
                        complete_frames * FRAME_SIZE:
                    ]

                    pending = bytearray(remainder)

                    raw = np.frombuffer(
                        raw_bytes,
                        dtype=np.uint8
                    ).reshape(HEIGHT, WIDTH)

                    # RGB332 -> RGB888
                    raw = raw.astype(np.uint16)

                    r = ((raw >> 5) & 0x07) * 255 // 7
                    g = ((raw >> 2) & 0x07) * 255 // 7
                    b = (raw & 0x03) * 255 // 3

                    last_frame = np.stack(
                        (r, g, b),
                        axis=-1
                    ).astype(np.uint8)

            # Display latest complete frame
            surface = pygame.image.frombuffer(
                last_frame.tobytes(),
                (WIDTH, HEIGHT),
                "RGB"
            )

            scaled = pygame.transform.scale(
                surface,
                (WIDTH * SCALE, HEIGHT * SCALE)
            )

            screen.blit(scaled, (0, 0))
            pygame.display.flip()

            clock.tick(60)

pygame.quit()
