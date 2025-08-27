
# import libraries
import os

# 기본 출력 디렉토리 설정
DEFAULT_OUTPUT_DIR = "output"

def dectohex(input_filename, output_filename, data_path=""):
    """
    입력 파일에서 10진수를 읽어 16비트 16진수 문자열(접두사 없음)로 변환하고,
    이를 출력 파일에 한 줄씩 씁니다.

    Args:
        input_filename (str): 10진수가 포함된 입력 파일 이름.
        output_filename (str): 16진수 문자열을 쓸 출력 파일 이름.
        data_path (str, optional): 입출력 파일의 디렉토리 경로. 기본값은 현재 디렉토리.
    """
    input_filepath = os.path.join(data_path, input_filename)
    output_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, output_filename)

    os.makedirs(os.path.join(data_path, DEFAULT_OUTPUT_DIR), exist_ok=True)

    print(f"10진수 -> 16비트 16진수 변환 시작 (접두사 없음)...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")

    try:
        with open(input_filepath, 'r') as infile, open(output_filepath, 'w') as outfile:
            lines_processed = 0
            for line in infile:
                line = line.strip()
                if not line:
                    continue
                try:
                    decimal_val = int(line)

                    # 16비트 16진수로 변환 (접두사 "0x" 없이)
                    if 0 <= decimal_val <= 0xFFFF:  # 부호 없는 16비트
                        hex_val = f"{decimal_val:04X}"
                    elif -0x8000 <= decimal_val < 0:  # 부호 있는 16비트
                        hex_val = f"{(decimal_val + 0x10000):04X}"
                    else:
                        print(f"경고: {lines_processed + 1}번째 줄의 값 {decimal_val}이(가) 16비트 범위를 벗어났습니다.")
                        outfile.write(f"오류: 값 {decimal_val}이(가) 16비트 범위를 벗어남\n")
                        continue
                    
                    outfile.write(hex_val + "\n")
                    lines_processed += 1
                except ValueError:
                    print(f"경고: '{line}' 줄을 정수로 변환할 수 없습니다.")
                    outfile.write(f"오류: 잘못된 10진수 값 '{line}'\n")
            print(f"변환 완료. {lines_processed}개의 유효한 10진수를 처리했습니다.")
    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
    except Exception as e:
        print(f"dectohex 함수에서 예기치 않은 오류 발생: {e}")

def hex_flatten(input_filename, output_filename, rows, cols, transpose, flatten_bitlen, data_path=""):
    """
    입력 파일의 16비트 16진수 값(접두사 없음)들을 읽어 매트릭스로 처리하고,
    선택적으로 전치한 후 'flatten_bitlen'에 맞춰 그룹화하고, 각 그룹 내
    요소들의 순서를 뒤집어 (LSB -> MSB) 출력 파일에 씁니다.

    Args:
        input_filename (str): 16진수 문자열이 포함된 입력 파일 이름.
        output_filename (str): 최종 결과를 저장할 출력 파일 이름.
        rows (int): 원본 데이터의 행 수.
        cols (int): 원본 데이터의 열 수.
        transpose (bool): True이면 매트릭스를 전치하고, False이면 원본 순서대로 처리.
        flatten_bitlen (int): 출력 파일의 한 줄에 쓸 총 비트 수. 16의 배수여야 함.
        data_path (str, optional): 입출력 파일의 디렉토리 경로. 기본값은 현재 디렉토리.
    """
    input_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, input_filename)
    output_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, output_filename)

    os.makedirs(os.path.join(data_path, DEFAULT_OUTPUT_DIR), exist_ok=True)

    if flatten_bitlen <= 0 or flatten_bitlen % 16 != 0:
        print("오류: flatten_bitlen은 양수이면서 16의 배수여야 합니다 (각 요소는 16비트).")
        return
    
    if rows <= 0 or cols <= 0:
        print("오류: rows와 cols는 양수여야 합니다.")
        return

    print(f"\n16비트 16진수 매트릭스 병합 작업 시작 (접두사 없음)...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")
    print(f"원본 매트릭스 크기: {rows}x{cols}")
    print(f"Transpose 적용: {transpose}")
    print(f"줄당 비트 수 (flatten_bitlen): {flatten_bitlen} 비트 (LSB->MSB 순서로 저장)")

    raw_hex_elements = []
    try:
        with open(input_filepath, 'r') as infile:
            for line_num, line_content in enumerate(infile, 1):
                hex_data_part = line_content.strip()
                if not hex_data_part:
                    continue
                
                if not all(c in "0123456789abcdefABCDEF" for c in hex_data_part):
                    print(f"오류: 입력 파일 {line_num}번째 줄 '{hex_data_part}'에서 유효한 16진수 데이터를 찾을 수 없습니다.")
                    return
                
                # 16비트(4자리)에 맞게 처리
                hex_data_part = hex_data_part.zfill(4)
                if len(hex_data_part) > 4:
                    print(f"오류: 입력 파일 {line_num}번째 줄 '{hex_data_part}'의 데이터가 16비트를 초과합니다.")
                    return
                
                raw_hex_elements.append(hex_data_part.upper())
    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
        return
    except Exception as e:
        print(f"입력 파일 읽기 중 오류 발생: {e}")
        return

    if len(raw_hex_elements) != rows * cols:
        print(f"오류: 파일 요소 수({len(raw_hex_elements)})가 매트릭스 크기({rows*cols})와 일치하지 않습니다.")
        return

    elements_to_write = []
    if transpose:
        print(f"데이터를 {cols}x{rows} 매트릭스로 전치합니다...")
        for j_new_row in range(cols): 
            for i_new_col in range(rows): 
                original_index = i_new_col * cols + j_new_row
                elements_to_write.append(raw_hex_elements[original_index])
    else:
        print("데이터를 원본 순서대로 처리합니다...")
        elements_to_write = raw_hex_elements

    # 파일에 쓰기 (LSB -> MSB 순서 적용)
    elements_per_output_line = flatten_bitlen // 16 # 각 요소는 16비트

    print(f"병합된 16진수를 파일에 쓰는 중... (줄당 {elements_per_output_line}개 요소)")
    try:
        with open(output_filepath, 'w') as outfile:
            for i in range(0, len(elements_to_write), elements_per_output_line):
                chunk = elements_to_write[i : i + elements_per_output_line]
                reversed_chunk = chunk[::-1]
                output_line = "".join(reversed_chunk)
                outfile.write(output_line + "\n")
            
            print(f"병합 완료. 총 {len(elements_to_write)}개의 16비트 요소를 처리하여 '{output_filepath}'에 저장했습니다.")

    except Exception as e:
        print(f"hex_flatten 함수에서 파일 쓰기 중 예기치 않은 오류 발생: {e}")


hex_flatten("fixed_point_W2_hex.txt", "fixed_point_W2_flat_1024_t_F.txt", 64, 256, False, 1024)
hex_flatten("fixed_point_W3_hex.txt", "fixed_point_W3_flat_2048_t_T.txt", 128, 256, True, 2048)
hex_flatten("fixed_point_W4_hex.txt", "fixed_point_W4_flat_160_t_T.txt", 10, 128, True, 160)

