'''
///////////////////////////////
PSEUDO CODE

# import libraries

DATA_NAME = "filename.txt"
DATA_PATH = ""

def dectohex(data_name, data_path):
    # read text lines (list format)
    for line in lines:
        #convert to 16bit hex
        #write to output file


def hex_flatten(data_name, data_path, flatten_bitlen):
    # read text lines (list format)
    # fetch length of list
    for line in lines:
        # write 16bit hex to file
        # if it made past flatten_bitlen, write newline
'''

import os
import numpy as np

DEFAULT_OUTPUT_DIR = "output"

def dectohex(input_filename, output_filename, data_path=""):
    """
    입력 파일에서 10진수를 읽어 16비트 16진수 문자열로 변환하고,
    이를 출력 파일에 한 줄씩 씁니다.

    Args:
        input_filename (str): 10진수가 포함된 입력 파일 이름.
        output_filename (str): 16진수 문자열을 쓸 출력 파일 이름.
        data_path (str, optional): 입출력 파일의 디렉토리 경로. 기본값은 현재 디렉토리.
    """
    input_filepath = os.path.join(data_path, input_filename)
    output_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, output_filename)

    os.makedirs(os.path.join(data_path, DEFAULT_OUTPUT_DIR), exist_ok=True)

    print(f"10진수 -> 16진수 변환 시작...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")

    try:
        with open(input_filepath, 'r') as infile, open(output_filepath, 'w') as outfile:
            lines_processed = 0
            for line in infile:
                line = line.strip()  # 줄 앞뒤의 공백 제거
                if not line:
                    continue
                try:
                    decimal_val = int(line)

                    if 0 <= decimal_val <= 0xFFFF:
                        hex_val = f"{decimal_val:04X}"
                    elif -0x8000 <= decimal_val < 0:
                        hex_val = f"{(decimal_val + 0x10000):04X}"
                    else:
                        print(f"경고: {lines_processed + 1}번째 줄의 10진수 값 {decimal_val}이(가) 16비트 범위를 벗어났습니다. 건너<0xEB><0><0x84>니다.")
                        outfile.write(f"오류: 값 {decimal_val}이(가) 16비트 범위를 벗어남\n")
                        continue
                    
                    outfile.write(hex_val + "\n")
                    lines_processed += 1
                except ValueError:
                    print(f"경고: '{line}' 줄을 정수로 변환할 수 없습니다. 건너<0xEB><0><0x84>니다.")
                    outfile.write(f"오류: 잘못된 10진수 값 '{line}'\n")
            print(f"변환 완료. {lines_processed}개의 유효한 10진수를 처리했습니다.")
    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
    except Exception as e:
        print(f"dectohex 함수에서 예기치 않은 오류 발생: {e}")

def hex_flatten(
    input_filename,
    output_filename,
    flatten_bitlen,
    data_path="",
    if_adder=True
    ):


    input_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, input_filename)
    output_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, output_filename)
    os.makedirs(os.path.join(data_path, DEFAULT_OUTPUT_DIR), exist_ok=True)

    if flatten_bitlen <= 0 or flatten_bitlen % 4 != 0:
        print("오류: flatten_bitlen은 양수이면서 4의 배수여야 합니다.")
        return

    print(f"\n16진수 병합 작업 시작...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")
    print(f"줄당 비트 수: {flatten_bitlen} 비트")

    chars_per_line = flatten_bitlen // 4
    current_line_chars = 0  # 현재 줄에 쓰인 문자 수
    processed_hex_values = 0

    try:
        with open(input_filepath, 'r') as infile, open(output_filepath, 'w') as outfile:
            for line_number, line in enumerate(infile, 1):
                hex_string = line.strip() 
                if not hex_string: 
                    continue

                else:
                    hex_data = hex_string
                    count = count+1
                
                if not all(c in "0123456789abcdefABCDEF" for c in hex_data):
                    print(f"경고: 입력 파일의 {line_number}번째 줄에 있는 '{hex_string}'에 잘못된 16진수 문자가 포함되어 있습니다. 건너<0xEB><0><0x84>니다.")
                    outfile.write(f"오류: 잘못된 16진수 문자열 '{hex_string}'\n") # 추적을 위해 오류를 출력 파일에 기록
                    continue
                
                for char_val in hex_data:
                    outfile.write(char_val)
                    current_line_chars += 1
                    # 현재 줄에 쓰인 문자 수가 chars_per_line에 도달하면 줄바꿈
                    if current_line_chars >= chars_per_line:
                        outfile.write("\n")
                        current_line_chars = 0
                processed_hex_values +=1

            # 마지막 줄이 줄바꿈으로 끝나지 않은 경우 (줄이 꽉 차지 않아서)
            if current_line_chars > 0:
                outfile.write("\n")
            print(f"병합 완료. {processed_hex_values}개의 16진수 값을 처리했습니다.\n")

    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
    except Exception as e:
        print(f"hex_flatten 함수에서 예기치 않은 오류 발생: {e}")

# --- 이 아래는 함수 사용 예제 부분이므로 요청에 따라 제거합니다. ---
# if __name__ == "__main__":
#     # ... (이전 예제 코드)

def num_flatten(label, num):
    dectohex(f"{num}_label_{label}.txt", f"hex_{num}_label_{label}.txt")
    hex_flatten(f"hex_{num}_label_{label}.txt", f"flat_{num}_label_{label}.txt", 3136)

num_flatten(2, 1)
num_flatten(1, 2)
num_flatten(0, 3)
num_flatten(4, 4)
num_flatten(9, 7)
num_flatten(5, 8)
num_flatten(6, 11)
num_flatten(7, 17)
num_flatten(3, 18)
num_flatten(8, 110)

hex_flatten("fixed_point_W1_hex.txt", "fixed_point_W1_flat_3136.txt", 3136)
hex_flatten("fixed_point_W2_hex.txt", "fixed_point_W2_flat_1024.txt", 1024)
hex_flatten("fixed_point_W3_hex.txt", "fixed_point_W3_flat_2048.txt", 2048)
hex_flatten("fixed_point_W4_hex.txt", "fixed_point_W4_flat_160.txt", 160)
