import serial
import time
import random

PORT = 'COM10'
BAUDRATE = 115200

HEADER_1 = 0x55
HEADER_2 = 0xAA
PAYLOAD_LENGTH = 13


def generate_packet(payload_size):
    payload = random.randbytes(payload_size)
    return bytes([HEADER_1, HEADER_2]) + payload


def test_stream_echo(port, baudrate):
    packet = generate_packet(PAYLOAD_LENGTH)

    try:
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1.0
        )
    except serial.SerialException as e:
        print(f"Serial port error: {e}")
        return

    try:
        ser.reset_input_buffer()
        ser.reset_output_buffer()
        time.sleep(0.1)

        print(f"Sending packet ({len(packet)} bytes), waiting for echo byte-by-byte...")
        received_bytes = bytearray()

        for i, b in enumerate(packet):
            ser.write(bytes([b]))
            rx = ser.read(1)

            if rx:
                received_bytes.extend(rx)
            else:
                print(f"Timeout on byte 0x{b:02X} (index {i})")
                break

        print(f"\nSent       : {packet.hex(' ').upper()}")
        print(f"Received   : {received_bytes.hex(' ').upper()}")

        if received_bytes == packet:
            print(f"\n>>> ALL {len(packet)} BYTES RECEIVED AND ECHOED WITHOUT ERRORS! <<<")
        else:
            print(f"\nERROR: Received length {len(received_bytes)} / {len(packet)}")
    finally:
        ser.close()


if __name__ == '__main__':
    test_stream_echo(PORT, BAUDRATE)