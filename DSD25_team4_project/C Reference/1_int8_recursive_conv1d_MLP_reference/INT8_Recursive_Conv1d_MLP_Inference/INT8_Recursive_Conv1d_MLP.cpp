
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#pragma warning(disable : 4996)


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

    else if (element_size == "int32_t") {
        int32_t* data = (int32_t*)array;
        for (size_t i = 0; i < num_elements; i++) {
            fprintf(file, "%d\n", data[i]);
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
int load_weights_from_file(const char* filename, int8_t** weights, size_t num_elements) {
    FILE* fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error: failed to open file %s\n", filename);
        return -1;
    }
    for (size_t i = 0; i < num_elements; i++) {
        int32_t value;
        if (fscanf(fp, "%d", &value) != 1) {
            fprintf(stderr, "Error: failed to read file %s\n", filename);
            fclose(fp);
            return -1;
        }
        (*weights)[i] = (int32_t)value;
    }
    fclose(fp);
    return 0;
}


// Define the structure of the Conv1d_MLP model
struct Conv1d_MLP {
    int8_t* weight_Conv1d;
    int8_t* weight_Linear1;
    int8_t* weight_Linear2;
    int8_t* weight_Linear3;
};


// inference on MNIST data
int inference(const int32_t* input_image, struct Conv1d_MLP* model,
    float input_scale,  float weight_Conv1d_scale,
    float layer1_scale, float weight_Linear1_scale,
    float layer2_scale, float weight_Linear2_scale,
    float layer3_scale, float weight_Linear3_scale)
{

    // Define the input and output arrays
    float input_intermediate[784];
    uint8_t input[784];
    float layer1_intermediate[64];
    int8_t layer1_output[64];
    float layer2_intermediate[128];
    int8_t layer2_output[128];
    float layer3_intermediate[64];
    int8_t layer3_output[64];
    int32_t output[10];


    // Convert the input image to the input array
    for (int i = 0; i < 784; i++) {

        /*  Originally

            First, you have to normalize the input_image pixel values to the range [0, 1] by dividing each value by 255

            // input_intermediate[i] = (float)(input_image[i] / 255.0)         // To Normalize

            Sencod, Quantize the input_intermediate values by dividing each value by fc1_scale

            // input_intermediate[i] = (input_intermediate[i] / input_scale);     // To Qunatize

            But, For your convinience, we converted the value "(255.0*input_scale)" to a fixed - point value.

            Using fixed - point value "2" for normalize & quantization
            And you can rounding for better accuracy.
        */

        input_intermediate[i] = (float)(input_image[i] / 2.0);         // (255.0*input_scale) = (255.0*0.0078735351562500) = 2.0 ( Q 16.16 fixed-point value )

        input_intermediate[i] = (input_intermediate[i] > 0) ? input_intermediate[i] + 0.5 : input_intermediate[i] - 0.5;        // rounding for better acruacy 
        input[i] = (input_intermediate[i] > 127) ? 127 : (input_intermediate[i] < -127) ? -127 : (uint8_t)input_intermediate[i];      // clipping
    }
    save_output_to_file("./save_data/normalized_quantized_input.txt", input, "int8_t", 784);


    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                        Conv1d_MLP First Layer ( Conv1d Layer )             784 -> 64
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the first layer of the Conv1d_MLP
    for (int i = 0; i < 64; i++) {
        layer1_intermediate[i] = 0;
        layer1_output[i] = 0;
        for (int j = 0; j < 28; j++) {
            layer1_intermediate[i] += (float)(input[i * 12 + j] * model->weight_Conv1d[j]);
        }
    }
    save_output_to_file("./save_data/layer1_intermediate.txt", layer1_intermediate, "float", 64);


    // relu
    for (int i = 0; i < 64; i++) {
        if (layer1_intermediate[i] < 0) layer1_intermediate[i] = 0;
    }

    // Deqauntize the result
    for (int i = 0; i < 64; i++) {
        // scaling : int32 -> fp32
        layer1_intermediate[i] = (float)(layer1_intermediate[i] * input_scale * weight_Conv1d_scale);
    }

    // Quantize the result
    for (int i = 0; i < 64; i++) {
        // scaling : fp32 -> int8
        layer1_intermediate[i] = (float)(layer1_intermediate[i] / layer1_scale);  //Actually, this value is for int8 but, we saved as float for rounding and clipping.
        // rounding
        layer1_intermediate[i] = (layer1_intermediate[i] > 0) ? layer1_intermediate[i] + 0.5 : layer1_intermediate[i] - 0.5;
        // clipping
        layer1_output[i] = (layer1_intermediate[i] > 127) ? 127 : (layer1_intermediate[i] < -127) ? -127 : (int8_t)layer1_intermediate[i]; // saved as int8 
    }
    save_output_to_file("./save_data/layer1_output.txt", layer1_output, "int8_t", 64);


    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                        Conv1d_MLP Second Layer ( Linear Layer 1 )          64 -> 128
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the second layer of the Conv1d_MLP
    for (int i = 0; i < 128; i++) {
        layer2_intermediate[i] = 0;
        layer2_output[i] = 0;
        for (int j = 0; j < 64; j++) {
            layer2_intermediate[i] += (float)(layer1_output[j] * model->weight_Linear1[i * 64 + j]);
        }
    }
    save_output_to_file("./save_data/layer2_intermediate.txt", layer2_intermediate, "float", 128);


    // relu
    for (int i = 0; i < 128; i++) {
        if (layer2_intermediate[i] < 0) layer2_intermediate[i] = 0;
    }

    // Deqauntize the result
    for (int i = 0; i < 128; i++) {
        // scaling : int32 -> fp32
        layer2_intermediate[i] = (float)(layer2_intermediate[i] * layer1_scale * weight_Linear1_scale);
    }

    // Quantize the result
    for (int i = 0; i < 128; i++) {
        // scaling : fp32 -> int8
        layer2_intermediate[i] = (float)(layer2_intermediate[i] / layer2_scale);  //Actually, this value is for int8 but, we saved as float for rounding and clipping.
        // rounding
        layer2_intermediate[i] = (layer2_intermediate[i] > 0) ? layer2_intermediate[i] + 0.5 : layer2_intermediate[i] - 0.5;
        // clipping
        layer2_output[i] = (layer2_intermediate[i] > 127) ? 127 : (layer2_intermediate[i] < -127) ? -127 : (int8_t)layer2_intermediate[i]; // saved as int8 
    }
    save_output_to_file("./save_data/layer2_output.txt", layer2_output, "int8_t", 128);


    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                        Conv1d_MLP third Layer ( Linear Layer 2 )           128-> 64
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the third layer of the Conv1d_MLP
    for (int i = 0; i < 64; i++) {
        layer3_intermediate[i] = 0;
        layer3_output[i] = 0;
        for (int j = 0; j < 128; j++) {
            layer3_intermediate[i] += (float)(layer2_output[j] * model->weight_Linear2[i * 128 + j]);
        }
    }
    save_output_to_file("./save_data/layer3_intermediate.txt", layer3_intermediate, "float", 64);


    // relu
    for (int i = 0; i < 64; i++) {
        if (layer3_intermediate[i] < 0) layer3_intermediate[i] = 0;
    }

    // Deqauntize the result
    for (int i = 0; i < 64; i++) {
        // scaling : int32 -> fp32
        layer3_intermediate[i] = (float)(layer3_intermediate[i] * layer2_scale * weight_Linear2_scale);
    }

    // Quantize the result
    for (int i = 0; i < 64; i++) {
        // scaling : fp32 -> int8
        layer3_intermediate[i] = (float)(layer3_intermediate[i] / layer3_scale);  //Actually, this value is for int8 but, we saved as float for rounding and clipping.
        // rounding
        layer3_intermediate[i] = (layer3_intermediate[i] > 0) ? layer3_intermediate[i] + 0.5 : layer3_intermediate[i] - 0.5;
        // clipping
        layer3_output[i] = (layer3_intermediate[i] > 127) ? 127 : (layer3_intermediate[i] < -127) ? -127 : (int8_t)layer3_intermediate[i]; // saved as int8 
    }
    save_output_to_file("./save_data/layer3_output.txt", layer3_output, "int8_t", 64);


    /*
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                        Conv1d_MLP forth Layer ( Linear Layer 3)            64 -> 10
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    */

    // Perform the forth layer of the Conv1d_MLP
    for (int i = 0; i < 10; i++) {
        output[i] = 0;
        for (int j = 0; j < 64; j++) {
            output[i] += (int32_t)(layer3_output[j] * model->weight_Linear3[i * 64 + j]);
        }
    }
    save_output_to_file("./save_data/output.txt", output, "int32_t", 10);


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

    // Initialize MLP structure
    struct Conv1d_MLP model;

    // Allocate memory for the weight matrix & Load the weights from file
    model.weight_Conv1d = (int8_t*)malloc(28 * sizeof(int8_t));
    model.weight_Linear1 = (int8_t*)malloc(64 * 128 * sizeof(int8_t));
    model.weight_Linear2 = (int8_t*)malloc(128 * 64 * sizeof(int8_t));
    model.weight_Linear3 = (int8_t*)malloc(64 * 10 * sizeof(int8_t));

    if (load_weights_from_file("./INT8_weight/int8_weight_Conv1d_dec.txt", &model.weight_Conv1d, 28) != 0) { return -1; }
    if (load_weights_from_file("./INT8_weight/int8_weight_Linear1_dec.txt", &model.weight_Linear1, 64 * 128) != 0) { return -1; }
    if (load_weights_from_file("./INT8_weight/int8_weight_Linear2_dec.txt", &model.weight_Linear2, 128 * 64) != 0) { return -1; }
    if (load_weights_from_file("./INT8_weight/int8_weight_Linear3_dec.txt", &model.weight_Linear3, 64 * 10) != 0) { return -1; }

    // Define the quantization parameters
    // these parameters are set as Q16.16 fixed-point value ( 1-bit for signed , 15-bit for integer part, 16-bit for fractional part )
    float input_scale = 0.0078735351562500;
    float weight_Conv1d_scale = 0.0066528320312500;
    float layer1_scale = 0.0216522216796875;
    float weight_Linear1_scale = 0.0067901611328125;
    float layer2_scale = 0.0150451660156250;
    float weight_Linear2_scale = 0.0059051513671875;
    float layer3_scale = 0.0238800048828125;
    float weight_Linear3_scale = 0.0026397705078125;


    /*
    Option 1. Inference for multiple input image.
        You can inference 1~9999 testdataset at once by adjusting "num_files" value.
        You can check the accuracy for test dataset.
    */

    // If you want Option 1, change 0 to 1
    #if 0
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

                int result = inference(input_image, &model,
                    input_scale, weight_Conv1d_scale,
                    layer1_scale, weight_Linear1_scale,
                    layer2_scale, weight_Linear2_scale,
                    layer3_scale, weight_Linear3_scale);

                if (y_label == result) correct_count = correct_count + 1;
                printf("Input Data Path :'%s', label=%d, result=% d, compare=% d \n ", filename, y_label, result, (y_label == result));
                fclose(file);
                break;
            }
        }
    }

    printf("correct_count = %d\n", correct_count);

    //// Calcurate the accuracy & Print
    accuracy = (float)correct_count / (float)num_files * 100;
    printf(" Accuracy : %.2f \n", accuracy);
    #endif

    /*
    Option 2. Inference for single specific input image.
        You can get the intermediate value of specific input image.
    */

    // If you want Option 2, change 0 to 1
    #if 1
    const char* filename = "./mnist_testset_txt_per_pixel/1_label_2.txt";
    int y_label;    // the true label for the specific image
    sscanf(strrchr(filename, '_') + 1, "%d", &y_label);
    int32_t input_image[784];

    FILE* file = fopen(filename, "r");

    if (file != NULL) {
        for (size_t i = 0; i < 784; i++) {
            int value;
            if (fscanf(file, "%d", &value) != 1) {
                fprintf(stderr, "error: failed to read file %s\n", filename);
                fclose(file);
                return -1;
            }
            input_image[i] = (int32_t)value;
        }

        int result = inference(input_image, &model,
            input_scale, weight_Conv1d_scale,
            layer1_scale, weight_Linear1_scale,
            layer2_scale, weight_Linear2_scale,
            layer3_scale, weight_Linear3_scale);

        printf("input data path: '%s', label=%d, result=%d\n", filename, y_label, result);
        fclose(file);
    }
    else {
        fprintf(stderr, "error: failed to open file %s\n", filename);
    }
    #endif

    //--------------------------------------------------------------------------------------------------------------------------------

    return 0;
}


