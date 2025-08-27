# import libraries
import os

# 기본 출력 디렉토리 설정
DEFAULT_OUTPUT_DIR = "output"
# 16진수 접두사
HEX_PREFIX = "0x"

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
    # 출력 파일은 'output' 하위 디렉토리에 생성되도록 경로 설정
    output_filepath = os.path.join(data_path, DEFAULT_OUTPUT_DIR, output_filename)

    # 출력 디렉토리가 없으면 생성
    os.makedirs(os.path.join(data_path, DEFAULT_OUTPUT_DIR), exist_ok=True)

    print(f"10진수 -> 16진수 변환 시작...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")

    try:
        # 입력 파일을 읽기 모드('r')로, 출력 파일을 쓰기 모드('w')로 엽니다.
        with open(input_filepath, 'r') as infile, open(output_filepath, 'w') as outfile:
            lines_processed = 0
            # 입력 파일의 각 줄에 대해 반복
            for line in infile:
                line = line.strip()  # 줄 앞뒤의 공백 제거
                if not line:  # 빈 줄은 건너뛰기
                    continue
                try:
                    # 문자열을 정수로 변환
                    decimal_val = int(line)

                    # 16비트 16진수로 변환
                    # {0:04X}는 숫자를 4자리 대문자 16진수 문자열로 포맷하고, 필요하면 0으로 채웁니다.
                    # 음수는 16비트 2의 보수로 처리합니다.
                    if 0 <= decimal_val <= 0xFFFF:  # 부호 없는 16비트 최대값
                        hex_val = f"{HEX_PREFIX}{decimal_val:04X}"
                    elif -0x8000 <= decimal_val < 0:  # 부호 있는 16비트 최소값
                        # 16비트 2의 보수: (decimal_val + (1 << 16)) % (1 << 16)
                        hex_val = f"{HEX_PREFIX}{(decimal_val + 0x10000):04X}"
                    else:
                        # 16비트 범위를 벗어나는 경우 경고 메시지를 출력하고 다음 줄로 넘어갑니다.
                        print(f"경고: {lines_processed + 1}번째 줄의 10진수 값 {decimal_val}이(가) 16비트 범위를 벗어났습니다. 건너<0xEB><0><0x84>니다.")
                        outfile.write(f"오류: 값 {decimal_val}이(가) 16비트 범위를 벗어남\n")
                        continue
                    
                    # 변환된 16진수 값을 출력 파일에 씁니다.
                    outfile.write(hex_val + "\n")
                    lines_processed += 1
                except ValueError:
                    # 정수로 변환할 수 없는 경우 경고 메시지를 출력합니다.
                    print(f"경고: '{line}' 줄을 정수로 변환할 수 없습니다. 건너<0xEB><0><0x84>니다.")
                    outfile.write(f"오류: 잘못된 10진수 값 '{line}'\n")
            print(f"변환 완료. {lines_processed}개의 유효한 10진수를 처리했습니다.")
    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
    except Exception as e:
        print(f"dectohex 함수에서 예기치 않은 오류 발생: {e}")

def hex_flatten(input_filename, output_filename, rows, cols, transpose, flatten_bitlen, data_path=""):
    """
    입력 파일의 16진수 값들을 읽어 매트릭스로 처리하고, 선택적으로 전치합니다.
    그 후 'flatten_bitlen'에 맞춰 그룹화하고, 각 그룹 내 요소들의 순서를
    뒤집어 (MSB -> LSB) 출력 파일에 씁니다.

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

    print(f"\n16진수 매트릭스 병합 작업 시작...")
    print(f"입력 파일: {input_filepath}")
    print(f"출력 파일: {output_filepath}")
    print(f"원본 매트릭스 크기: {rows}x{cols}")
    print(f"Transpose 적용: {transpose}")
    print(f"줄당 비트 수 (flatten_bitlen): {flatten_bitlen} 비트 (MSB->LSB 순서로 저장)")

    raw_hex_elements = []
    try:
        with open(input_filepath, 'r') as infile:
            for line_num, line_content in enumerate(infile, 1):
                stripped_line = line_content.strip()
                if not stripped_line:
                    continue

                hex_data_part = ""
                if stripped_line.startswith(HEX_PREFIX):
                    hex_data_part = stripped_line[len(HEX_PREFIX):]
                else:
                    hex_data_part = stripped_line 
                
                if not hex_data_part or not all(c in "0123456789abcdefABCDEF" for c in hex_data_part):
                    print(f"오류: 입력 파일 {line_num}번째 줄 '{stripped_line}'에서 유효한 16진수 데이터를 찾을 수 없습니다. 작업을 중단합니다.")
                    return
                
                hex_data_part = hex_data_part.zfill(4)
                if len(hex_data_part) > 4:
                    print(f"오류: 입력 파일 {line_num}번째 줄 '{stripped_line}'의 데이터가 16비트를 초과합니다. 작업을 중단합니다.")
                    return
                
                raw_hex_elements.append(hex_data_part.upper())
    except FileNotFoundError:
        print(f"오류: 입력 파일 '{input_filepath}'을(를) 찾을 수 없습니다.")
        return
    except Exception as e:
        print(f"입력 파일 읽기 중 오류 발생: {e}")
        return

    if len(raw_hex_elements) != rows * cols:
        print(f"오류: 파일에서 읽은 요소의 수({len(raw_hex_elements)})가 지정된 매트릭스 크기({rows}x{cols}={rows*cols})와 일치하지 않습니다.")
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

    # 파일에 쓰기 (MSB -> LSB 순서 적용)
    elements_per_output_line = flatten_bitlen // 16 # 각 요소는 16비트

    print(f"병합된 16진수를 파일에 쓰는 중... (줄당 {elements_per_output_line}개 요소)")
    try:
        with open(output_filepath, 'w') as outfile:
            # 전체 리스트를 'elements_per_output_line' 크기의 청크(chunk)로 나눔
            for i in range(0, len(elements_to_write), elements_per_output_line):
                # 현재 줄에 해당하는 요소들의 청크를 가져옴
                chunk = elements_to_write[i : i + elements_per_output_line]

                # 청크 내 요소들의 순서를 뒤집음 (MSB -> LSB)
                reversed_chunk = chunk[::-1]

                # 뒤집힌 요소들을 하나의 문자열로 합쳐서 파일에 씀
                output_line = "".join(reversed_chunk)
                outfile.write(output_line + "\n")
            
            print(f"병합 완료. 총 {len(elements_to_write)}개의 16비트 요소를 처리하여 '{output_filepath}'에 저장했습니다.")

    except Exception as e:
        print(f"hex_flatten 함수에서 파일 쓰기 중 예기치 않은 오류 발생: {e}")



    
# --- 함수 사용 예제 ---
if __name__ == "__main__":
    TEST_DATA_PATH = "" 
    os.makedirs(os.path.join(TEST_DATA_PATH, DEFAULT_OUTPUT_DIR), exist_ok=True)

    # 1. 테스트용 10진수 입력 파일 생성 (2x3 매트릭스 데이터)
    decimal_matrix_input_filename = "decimal_matrix_input.txt"
    with open(os.path.join(TEST_DATA_PATH, decimal_matrix_input_filename), 'w') as f:
        f.write("0\n1\n2\n3\n4\n5\n") # MSB->LSB 테스트를 위해 간단한 숫자로 변경

    # 2. dectohex 실행
    hex_intermediate_filename = "hex_matrix_intermediate.txt"
    dectohex(decimal_matrix_input_filename, hex_intermediate_filename, TEST_DATA_PATH)
    print(f"--- 중간 16진수 파일 '{hex_intermediate_filename}' 생성 완료 ---")
    # 생성된 파일 내용: 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005

    # 3. hex_flatten 테스트 (MSB -> LSB 순서 확인)
    print("\n--- MSB -> LSB 순서 적용 테스트 ---")
    flattened_output_msb_lsb = "flattened_msb_lsb.txt"
    hex_flatten(
        input_filename=hex_intermediate_filename,
        output_filename=flattened_output_msb_lsb,
        rows=2, 
        cols=3, 
        transpose=False, 
        flatten_bitlen=48, # 48 비트 = 3개 요소
        data_path=TEST_DATA_PATH
    )
    # 입력 순서: 0000, 0001, 0002 | 0003, 0004, 0005
    # 출력 파일(flattened_msb_lsb.txt) 예상 내용:
    # 000200010000
    # 000500040003
    print(f"'{flattened_output_msb_lsb}' 파일의 내용을 확인하여 MSB->LSB 순서를 검증하세요.")
    
    print(f"\n--- 모든 테스트 완료 ---")
    print(f"결과 파일은 '{os.path.join(TEST_DATA_PATH, DEFAULT_OUTPUT_DIR)}' 디렉토리를 확인하세요.")

