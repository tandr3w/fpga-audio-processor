# Script to convert between .txt and .wav files

import numpy as np
from scipy.io import wavfile
import sys
import os

# --- CONFIGURATION ---
INPUT_WAV  = "scripts/test_input2.wav"
INPUT_HEX  = "scripts/input2.txt"
OUTPUT_HEX = "scripts/output2.txt"
OUTPUT_WAV = "scripts/processed_output.wav"

def wav_to_hex():
    if not os.path.exists(INPUT_WAV):
        print(f"Error: {INPUT_WAV} not found.")
        return

    print(f"Converting {INPUT_WAV} -> {INPUT_HEX}...")
    rate, data = wavfile.read(INPUT_WAV)
    
    # Ensure data is 16-bit for consistency
    if data.dtype != np.int16:
        data = (data / np.max(np.abs(data)) * 32767).astype(np.int16)
    
    # Handle Stereo/Mono
    if len(data.shape) == 1: 
        data = np.column_stack((data, data))
    
    with open(INPUT_HEX, 'w') as f:
        for l, r in data:
            # Scale 16-bit audio up to the upper 16 bits of a 32-bit word
            l_val = int(l) << 16
            r_val = int(r) << 16
            
            # Convert to unsigned 32-bit hex strings
            l_hex = (l_val + (1 << 32)) % (1 << 32)
            r_hex = (r_val + (1 << 32)) % (1 << 32)
            
            f.write(f"{l_hex:08X} {r_hex:08X}\n")
    print(f"Done. Generated {len(data)} samples.")

def hex_to_wav():
    if not os.path.exists(OUTPUT_HEX):
        print(f"Error: {OUTPUT_HEX} not found. Run your simulation first!")
        return

    print(f"Converting {OUTPUT_HEX} -> {OUTPUT_WAV}...")
    left_channel = []
    right_channel = []
    
    with open(OUTPUT_HEX, 'r') as f:
        for line in f:
            parts = line.split()
            if len(parts) < 2: continue
            
            try:
                # 1. Check for 'xxxxxxxx' or non-hex junk and skip
                if 'x' in parts[0].lower() or 'x' in parts[1].lower():
                    continue
                
                l_raw = int(parts[0], 16)
                r_raw = int(parts[1], 16)
                
                # 2. Convert to Signed 32-bit integers
                if l_raw >= 0x80000000: l_raw -= 0x100000000
                if r_raw >= 0x80000000: r_raw -= 0x100000000
                
                # 3. SCALE DOWN: Move data from upper 16 bits back to lower 16 bits
                # This fixes the "Silent WAV" issue
                l_16bit = l_raw >> 16
                r_16bit = r_raw >> 16
                
                left_channel.append(l_16bit)
                right_channel.append(r_16bit)
                
            except ValueError:
                # Skip any malformed lines
                continue
            
    if not left_channel:
        print("Error: No valid audio data was found in the hex file.")
        return

    # Combine channels and force into 16-bit signed integer format for the WAV writer
    audio_data = np.column_stack((left_channel, right_channel)).astype(np.int16)
    
    # Save file (48kHz matches the DE1-SoC Audio Core clock)
    wavfile.write(OUTPUT_WAV, 44100, audio_data) # TODO: Allow this to be set in the command line
    print(f"Done. Saved {len(left_channel)} samples to {OUTPUT_WAV}.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "w2h": wav_to_hex()
        elif sys.argv[1] == "h2w": hex_to_wav()
        else: print("Usage: python audio_converter.py [w2h|h2w]")
    else:
        print("Usage: python audio_converter.py [w2h|h2w]")