////////////////////////////////////////////////////////////////////////////////////////////
////////////                   INT8 Recursive Conv1d MLP                        ////////////
////////////////////////////////////////////////////////////////////////////////////////////

# Model Detail Spec

input image     : 28 x 28
flatten input   : 784 x 1 (uint8)
normalied quantized input : 784 x 1 (int8)

layer 1 : conv1d layer
input           : 784 x 1   (int8)
weight          : 28 x 1    (int8)
intermediate    : 64 x 1    (float32)
output          : 64 x 1    (int8)

layer 2 : linear layer 1
input           : 64 x 1    (int8)
weight          : 128 x 64  (int8)
intermediate    : 128 x 1   (float32)
output          : 128 x 1   (int8)

layer 3 : linear layer 2
input           : 128 x 1   (int8)
weight          : 64 x 128  (int8)
intermediate    : 64 x 1    (float32)
output          : 64 x 1    (int8)

layer 4 : linear layer 3
input           : 64 x 1    (int8)
weight          : 10 x 64   (int8)
intermediate    : 10 x 1    (float32)
output          : 10 x 1    (int8)

weight linear1, weight linear2, weight linear3 is matrix (2-dimension) and it is stored in txt file by vector(1-dimension).
You must know the way weight is flattened, and the flatten method is represented in 'INT8_weight_order.png' file.



# Data Save

In code, there is 'save_output_to_file' function, and it save the data to 'save_data' file.
In present code, the data you can save is as follows.
    normalized_quantized_input  : normalized and quantized input data
    layer1_intermediate         : result of multiplication of 'normalized_quantized_input' and 'weight_Conv1d'
    layer1_output               : data after relu, dequant, quant on 'layer1_intermediate'
    layer2_intermediate         : result of multiplication of 'layer1_output' and 'weight_Linear1'
    layer2_output               : data after relu, dequant, quant on 'layer2_intermediate'
    layer3_intermediate         : result of multiplication of 'layer2_output' and 'weight_Linear2'
    layer3_output               : data after relu, dequant, quant on 'layer3_intermediate'
    output                      : result of multiplication of 'layer3_output' and 'weight_Linear3'

All data will be stored in decimal and pre-defined data type.

If you want to save data, please find 'save_output_to_file' function in code and uncomment it.
And If you want to save data that not included in the above, please add 'save_output_to_file' function by yourself.



# Execution

There is 2 Option of inference.

Option 1
Inference many MNIST data in 'mnist_testset_txt_per_pixel' file, and measure accuacy of model.
You can change amount of MNIST data.

Option 2
Inference only one MNIST data in 'mnist_testset_txt_per_pixel' file.
You can change the MNIST data by change the filename