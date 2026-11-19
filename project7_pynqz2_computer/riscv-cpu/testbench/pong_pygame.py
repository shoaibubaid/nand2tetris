#!/usr/bin/env python3
import socket
import struct
import sys
import time

import numpy as np
import pygame

HOST, PORT = "127.0.0.1", 50007
W, H = 320, 240
SCALE = 3
FRAME_SIZE = W * H
HID = {
    pygame.K_w: 0x1A,
    pygame.K_s: 0x16,
    pygame.K_i: 0x0C,
    pygame.K_k: 0x0E,
}


def recv_exact(sock, count):
    chunks = bytearray()
    while len(chunks) < count:
        data = sock.recv(count - len(chunks))
        if not data:
            raise ConnectionError("VPI simulator disconnected")
        chunks.extend(data)
    return bytes(chunks)


def connect():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    while True:
        try:
            sock.connect((HOST, PORT))
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            return sock
        except OSError:
            sock.close()
            print("Waiting for Verilog simulator/VPI bridge...", flush=True)
            time.sleep(0.5)
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)


def main():
    pygame.init()
    screen = pygame.display.set_mode((W * SCALE, H * SCALE))
    pygame.display.set_caption("Verilog Pong — W/S and I/K to move")
    pygame.key.set_repeat(180, 70)
    clock = pygame.time.Clock()
    sock = connect()
    print("Connected. Controls: W/S = left paddle, I/K = right paddle, Esc = quit")

    try:
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key in HID:
                        # 9-bit PS event: bit 8 = pressed, bits 7:0 = USB HID usage.
                        sock.sendall(struct.pack("!H", 0x100 | HID[event.key]))

            raw = recv_exact(sock, FRAME_SIZE)
            pixels = np.frombuffer(raw, dtype=np.uint8)
            r3 = (pixels >> 5) & 0x07
            g3 = (pixels >> 2) & 0x07
            b2 = pixels & 0x03
            rgb = np.empty((H, W, 3), dtype=np.uint8)
            rgb[:, :, 0] = (r3 * 255 // 7).reshape(H, W)
            rgb[:, :, 1] = (g3 * 255 // 7).reshape(H, W)
            rgb[:, :, 2] = (b2 * 255 // 3).reshape(H, W)
            surface = pygame.surfarray.make_surface(np.transpose(rgb, (1, 0, 2)))
            screen.blit(pygame.transform.scale(surface, (W * SCALE, H * SCALE)), (0, 0))
            pygame.display.flip()
            clock.tick(60)
    except (ConnectionError, OSError) as exc:
        print(f"Connection ended: {exc}", file=sys.stderr)
    finally:
        sock.close()
        pygame.quit()


if __name__ == "__main__":
    main()
