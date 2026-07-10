import torch
import coremltools as ct
import utils
import argparse

def convert_to_coreml(ckpt_path: str, save_path: str, img_size: tuple[int, int]):
    """
    args:
    ckpt_path - path to model weights.
    img_size - size of dummy input image. Contains (Width, Height) of image.
    save_path - path, that will be use to save converted model. Must be specified with model name.
    """
    
    device = "cpu"
    # Load model checkpoint
    model = utils.load_model(ckpt_path, device)
    model.eval()
    
    dummy_input = torch.rand(1, 3, img_size[0], img_size[1])
    traced_model = torch.jit.trace(model, dummy_input)
    
    converted_model = ct.convert(
        traced_model,
        convert_to="mlprogram",
        inputs=[ct.TensorType(name="x", shape=dummy_input.shape)],
        outputs=[ct.TensorType(name="img")],
        minimum_deployment_target=ct.target.iOS17,
    )
    converted_model.save(save_path + '.mlpackage')
    
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", type=str,default='./weights/best_model.pkl')
    parser.add_argument('--save-path', type=str, default='./converted/model')
    
    args = parser.parse_args()
    convert_to_coreml(args.model_path, args.save_path, (4032, 3024))