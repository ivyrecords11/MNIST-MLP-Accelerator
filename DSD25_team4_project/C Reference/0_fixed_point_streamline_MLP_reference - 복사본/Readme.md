////////////////////////////////////////////////////////////////////////////////////////////
////////////                        Fixed 16-bit MLP                            ////////////
////////////////////////////////////////////////////////////////////////////////////////////

# Model Detail Spec

input image     :  28 x  28     (uint8)
flatten input   :   1 x 784     (uint8)
normalized input :  1 x 784     (fixed16)

layer 1 : linear layer 1 + ReLU
input           :   1 x 784     (fixed16)
weight          : 784 x  64     (fixed16)
intermediate    :   1 x  64     (fixed64)
output          :   1 x  64     (fixed16)

layer 2 : linear layer 2 + ReLU
input           :   1 x  64     (fixed16)
weight          :  64 x 256     (fixed16)
intermediate    :   1 x 256     (fixed64)
output          :   1 x 256     (fixed16)

layer 3 : linear layer 3 + ReLU
input           :   1 x 256     (fixed16)
weight          : 256 x 128     (fixed16)
intermediate    :   1 x 128     (fixed64)
output          :   1 x 128     (fixed16)

layer 4 : linear layer 4
input           :   1 x 128     (fixed16)
weight          : 128 x  10     (fixed16)
intermediate    :   1 x  10     (fixed64)
output          :   1 x  10     (fixed32)

NOTE: Weight parameters in txt file are ordered in row-major.

# Data Save

In code, there is 'save_output_to_file' function, and it save the data to 'save_data' file.
In present code, the data you can save is as follows.
    normalized_input            : input data normalized to Fixed 16-bit
    layer1_intermediate         : result of multiplication of 'normalized_input' and 'weight_Linear1'
    layer1_output               : data after slice, clip, relu on 'layer1_intermediate'
    layer2_intermediate         : result of multiplication of 'layer1_output' and 'weight_Linear2'
    layer2_output               : data after slice, clip, relu on 'layer2_intermediate'
    layer3_intermediate         : result of multiplication of 'layer2_output' and 'weight_Linear3'
    layer3_output               : data after slice, clip, relu on 'layer3_intermediate'
    layer4_intermediate         : result of multiplication of 'layer2_output' and 'weight_Linear4'
    layer4_output               : data after slice, clip, relu on 'layer4_intermediate'

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