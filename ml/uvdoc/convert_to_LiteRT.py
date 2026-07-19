import argparse
import litert_torch
import torch
from utils import load_model

def convert_to_litert(ckpt_path: str, save_path: str, img_size: tuple[int, int]):
    # Load and prepare base model
    device = 'cpu'
    model = load_model(ckpt_path, device)
    model.to(device)
    model.eval()
    dummy_input = (torch.rand(1, 3, img_size[0], img_size[1]),)
    
    converted_model = litert_torch.convert(model, dummy_input)
    converted_model.export(save_path + 'model.tflite')
    
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    
    parser.add_argument('--weights_path', type=str, default='./weights/best_model.pkl')
    parser.add_argument('--save_path', type=str, default='./converted/')
    parser.add_argument('--height', type=int, default=4032)
    parser.add_argument('--width', type=int, default=3024)
    
    args = parser.parse_args()
    
    convert_to_litert(args.weights_path, args.save_path, (args.height, args.width))
    