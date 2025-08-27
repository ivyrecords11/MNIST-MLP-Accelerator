/*
 * 2025 modified by Seokkyu Yoon
 * skyoon@seoultech.ac.kr
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#pragma warning(disable : 4996)

//int CLIP_RANGE
//To save the arrays as test files with one value per line.
void save_output_to_file(const char* filename, void* array, const char* element_size, size_t num_elements) {
    FILE* file = fopen(filename, "w");
    if (file == NULL) {
        printf("Error opening file %s\n", filename);
        return;
    }

    if (element_size == "int8_t") {
        int8_t* data = (int8_t*)array;
        for (size_t i = 0; i < num_elements; i++) {
            fprintf(file, "%d\n", data[i]);
        }
    }

    else if (element_size == "int16_t") {
        int16_t* data = (int16_t*)array;
        for (size_t i = 0; i < num_elements; i++) {
            fprintf(file, "%d\n", data[i]);
        }
    }

    else if (element_size == "int32_t") {
        int32_t* data = (int32_t*)array;
        for (size_t i = 0; i < num_elements; i++) {
            fprintf(file, "%d\n", data[i]);
        }
    }

    else if (element_size == "int64_t") {
        int64_t* data = (int64_t*)array;
        for (size_t i = 0; i < num_elements; i++) {
            fprintf(file, "%lld\n", data[i]);
        }
    }

    else if (element_size == "float") {
        float* data = (float*)array;
        for (size_t i = 0; i < num_elements; i++) {
            int32_t int_data = (int32_t)data[i];
            fprintf(file, "%d\n", int_data);
        }
    }

    fclose(file);
}

// To load weights values from text files. (float)
int load_weights_from_file(const char* filename, int16_t** weights, size_t num_elements) {
    FILE* fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error: failed to open file %s\n", filename);
        return -1;
    }
    for (size_t i = 0; i < num_elements; i++) {
        int16_t value;
        if (fscanf(fp, "%hd", &value) != 1) {
            fprintf(stderr, "Error: failed to read file %s\n", filename);
            fclose(fp);
            return -1;
        }
        (*weights)[i] = (int16_t)((int16_t)value);
    }
    fclose(fp);
    return 0;
}

struct QuantizedMLP {
    int16_t* weight_layer1;
    int16_t* weight_layer2;
    int16_t* weight_layer3;
    int16_t* weight_layer4;
};


int inference(const int32_t* input_image, struct QuantizedMLP* model)
{
    // Define the input and output arrays
    int16_t input[784];
    int16_t layer1_output[64];
    int16_t layer2_output[256];
    int16_t layer3_output[128];
    int16_t output[10];
    int64_t layer_intermediate[256] = { 0, }; // For intermediate values

    //Normalize and 16-bit left shift
    // I binarized the inputs
    float intermediate_input[784] = { 0 };
    for (int i = 0; i < 784; i++) {
        //Normalize to 0~1 (원래 코드) (Q(8.8)로 변환)
        //intermediate_input[i] = (float)(input_image[i] / 256.0);
        intermediate_input[i] = (int16_t)((input_image[i] != 0));
        //bit shift and truncate
        //intermediate_input[i] *= 256; // 2^8 (256)
        input[i] = (int16_t)intermediate_input[i];
        
    }

    save_output_to_file("./save/normalized_input.txt", input, "int16_t", 784);

    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                            MLP First Layer ( Fully - connected Layer 1 )           784 -> 64
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the first layer of the MLP
    memset(layer_intermediate, 0, sizeof(layer_intermediate));
    for (int i = 0; i < 64; i++) {
        for (int j = 0; j < 784; j++) {
            layer_intermediate[i] += (int64_t)input[j] * model->weight_layer1[i * 784 + j];
            printf("MAC: %3d  clk: %3d  %4x %4x %8x \n", i, j, input[j], model->weight_layer1[i * 256 + j], layer_intermediate[i]);
        }

        //printf("%d\t", layer_intermediate[i]);
    }

    save_output_to_file("./save/layer1_intermediate.txt", layer_intermediate, "int64_t", 64);

    // Post-process the output
    for (int i = 0; i < 64; i++) {
        //Slice
        //layer_intermediate[i] = layer_intermediate[i] >> 8;

        //Clip to FP16 range
        if (layer_intermediate[i] > 32767)
            layer_intermediate[i] = 32767;
        else if (layer_intermediate[i] < -32768)
            layer_intermediate[i] = -32768;
        else
            layer_intermediate[i] = layer_intermediate[i];

        layer1_output[i] = (int16_t)(layer_intermediate[i]);
    }

    // ReLU
    for (int i = 0; i < 64; i++) {
        if (layer1_output[i] < 0)  layer1_output[i] = 0;
    }

    save_output_to_file("./save/layer1_output.txt", layer1_output, "int16_t", 64);

    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                            MLP Second Layer ( Fully - connected Layer 2 )          64 -> 256
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the second layer of the MLP
    memset(layer_intermediate, 0, sizeof(layer_intermediate));
    for (int i = 0; i < 256; i++) {
        for (int j = 0; j < 64; j++) {
            layer_intermediate[i] += (int64_t)layer1_output[j] * model->weight_layer2[i * 64 + j];
        }
    }

    save_output_to_file("./save/layer2_intermediate.txt", layer_intermediate, "int64_t", 256);

    // Post-process the output
    for (int i = 0; i < 256; i++) {
        //Slice
        layer_intermediate[i] = layer_intermediate[i] >> 7;

        //Clip to FP16 range
        if (layer_intermediate[i] > 32767)
            layer_intermediate[i] = 32767;
        else if (layer_intermediate[i] < -32768)
            layer_intermediate[i] = -32768;
        else
            layer_intermediate[i] = layer_intermediate[i];

        layer2_output[i] = (int16_t)(layer_intermediate[i]);
    }

    // ReLU
    for (int i = 0; i < 256; i++) {
        if (layer2_output[i] < 0)  layer2_output[i] = 0;
    }

    save_output_to_file("./save/layer2_output.txt", layer2_output, "int16_t", 256);

    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                            MLP third Layer ( Fully - connected Layer 3 )           256 -> 128
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */
    // Perform the third layer of the MLP
    memset(layer_intermediate, 0, sizeof(layer_intermediate));
    for (int i = 0; i < 128; i++) {
        for (int j = 0; j < 256; j++) {
            layer_intermediate[i] += (int64_t)layer2_output[j] * model->weight_layer3[i * 256 + j];
            //printf("MAC: %3d  clk: %3d  %4x %4x %8x \n", i, j, layer2_output[j], model->weight_layer3[i * 256 + j], layer_intermediate[i]);
        }
    }

    save_output_to_file("./save/layer3_intermediate.txt", layer_intermediate, "int64_t", 128);

    // Post-process the output
    for (int i = 0; i < 128; i++) {
        //Slice
        layer_intermediate[i] = layer_intermediate[i] >> 8;

        //Clip to FP16 range
        if (layer_intermediate[i] > 32767)
            layer_intermediate[i] = 32767;
        else if (layer_intermediate[i] < -32768)
            layer_intermediate[i] = -32768;
        else
            layer_intermediate[i] = layer_intermediate[i];

        layer3_output[i] = (int16_t)(layer_intermediate[i]);
    }

    // relu
    for (int i = 0; i < 128; i++) {
        if (layer3_output[i] < 0)  layer3_output[i] = 0;
    }

    save_output_to_file("./save/layer3_output.txt", layer3_output, "int16_t", 128);

    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                MLP output Layer ( Fully - connected Layer )            128 -> 10
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */
    // Perform the last layer of the MLP
    memset(layer_intermediate, 0, sizeof(layer_intermediate));
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 128; j++) {
            layer_intermediate[i] += (int64_t)layer3_output[j] * model->weight_layer4[i * 128 + j];
        }
    }

    save_output_to_file("./save/layer4_intermediate.txt", layer_intermediate, "int64_t", 10);

    // Post-process the output
    for (int i = 0; i < 10; i++) {
        //Slice
        layer_intermediate[i] = layer_intermediate[i] >> 8;

        //Clip to FP16 range
        if (layer_intermediate[i] > 32767)
            layer_intermediate[i] = 32767;
        else if (layer_intermediate[i] < -32768)
            layer_intermediate[i] = -32768;
        else
            layer_intermediate[i] = layer_intermediate[i];

        output[i] = (int16_t)(layer_intermediate[i]);
    }

    save_output_to_file("./save/layer4_output.txt", output, "int16_t", 10);

    // Find the index of the maximum output value
    int max_index = 0;
    for (int i = 1; i < 10; i++) {
        if (output[i] > output[max_index]) {
            max_index = i;
        }
    }

    // Return the index of the maximum output value
    return max_index;
}

int main() {
    setbuf(stdout, NULL);

    // Initialize QuantizedMLP structure
    struct QuantizedMLP model;

    // Allocate memory for the weight matrix & Load the weights from file
    model.weight_layer1 = (int16_t*)malloc(784 * 64 * sizeof(int16_t));
    model.weight_layer2 = (int16_t*)malloc(64 * 256 * sizeof(int16_t));
    model.weight_layer3 = (int16_t*)malloc(256 * 128 * sizeof(int16_t));
    model.weight_layer4 = (int16_t*)malloc(128 * 10 * sizeof(int16_t));
    if (load_weights_from_file("./q88_weight/fixed_point_W1_dec.txt", &model.weight_layer1, 784 * 64) != 0) { return -1; }
    if (load_weights_from_file("./q88_weight/fixed_point_W2_dec.txt", &model.weight_layer2, 64 * 256) != 0) { return -1; }
    if (load_weights_from_file("./q88_weight/fixed_point_W3_dec.txt", &model.weight_layer3, 256 * 128) != 0) { return -1; }
    if (load_weights_from_file("./q88_weight/fixed_point_W4_dec.txt", &model.weight_layer4, 128 * 10) != 0) { return -1; }


    /*
    Option 1. Inference for multiple input image.
        You can inference 1~9999 testdataset at once by adjusting "num_files" value.
        You can check the accuracy for test dataset.
    
    const int num_files = 9999;    // You can modify value by 1 ~ 9999 

    float accuracy = 0;
    int correct_count = 0;

    int y_label;
    char filename[100];
    for (int num = 1; num < num_files + 1; num++) {

        int found = 0;
        for (int label = 0; label <= 9 && !found; label++)
        {
            snprintf(filename, sizeof(filename), "./mnist_testset_txt_per_pixel/%d_label_%d.txt", num, label);

            FILE* file = fopen(filename, "r");

            if (file != NULL) {
                y_label = label;
                int32_t input_image[784];

                for (int i = 0; i < 784; i++) {
                    int value;
                    if (fscanf(file, "%d", &value) != 1) {
                        fprintf(stderr, "Error: failed to read file %s\n", filename);
                        fclose(file);
                        return -1;
                    }
                    input_image[i] = (int32_t)value;
                }

                int result = inference(input_image, &model);
                if (y_label == result) correct_count = correct_count + 1;
                printf("Input Data Path :'%s', label=%d, result=% d \n ", filename, y_label, result);
                fclose(file);
                break;
            }
        }
    }

    printf("correct_count = %d\n", correct_count);

    // Calcurate the accuracy & Print
    accuracy = (float)correct_count / (float)num_files * 100;
    printf(" Accuracy : %.2f \n", accuracy);

    */

    /*
    Option 2. Inference for single specific input image.
        You can get the intermediate value of specific input image.

    */


    const char* filename = "./mnist_testset_txt_per_pixel/1_label_2.txt";
    int y_label;    // The true label for the specific image
    sscanf(strrchr(filename, '_') + 1, "%d", &y_label);
    int32_t input_image[784];

    FILE* file = fopen(filename, "r");

    if (file != NULL) {
        for (size_t i = 0; i < 784; i++) {
            int value;
            if (fscanf(file, "%d", &value) != 1) {
                fprintf(stderr, "Error: failed to read file %s\n", filename);
                fclose(file);
                return -1;
            }
            input_image[i] = (int32_t)value;
        }

        int result = inference(input_image, &model);
        //int result = inference(input_image, &model, fc1_scale, w1_scale, fc2_scale, w2_scale, fc3_scale);

        printf("Input Data Path: '%s', label=%d, result=%d\n", filename, y_label, result);
        fclose(file);
    }
    else {
        fprintf(stderr, "Error: failed to open file %s\n", filename);
    }

    //--------------------------------------------------------------------------------------------------------------------------------

    return 0;
}



