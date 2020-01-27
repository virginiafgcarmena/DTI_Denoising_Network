The datasets have been obtained with create_ynet_dataset from data that has been cropped and registered (with crop_dataset and register_dataset, and process_average_matrix). 


In each dataset, there is a Nx3 cell:
1) Input image: 1st channel is the output sequence image, second channel is the other sequence, third channel: 0s
2) Denoised image
3) Tag

ALWAYS use the zerobelow0 before testing the network with the dataset!