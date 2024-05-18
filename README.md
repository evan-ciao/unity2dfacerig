# Unity 2D Face rig
Unity implementation of the [advanced 2D Blender rig created by TheSicklyWizard](https://www.youtube.com/watch?v=VZYm4mg1Eyo).

I highly suggest you watch my video at "under constr".
This is a lite implementation of that system in Unity, as I didn't need all the features.

## My modifications to the original rig
The system leverages the use of different UV maps, modified by bones, and blending of different textures to obtain the final 2D face.
To save on UV Maps as much as possible, as HLSL can only provide up to 8 UV channels, I compressed both eyes UV maps into one UV map. 
In total, the system uses a total of 5 UV maps :
  - BaseUV
  - Eye
  - Pupil.L
  - Pupil.R
  - Mouth

As you can see in the original video, the eyes texture-index (and mouth texture-index in my case) are animated through driver-driven custom-properties,
that I couldn't get exported with the model and be read by Unity (common issue with no documentation online. Animated custom-properties import seems to work only with Maya exported models).
To solve this issue I baked the eye-texture-index data and the mouth-texture-index data in the xy position of a bone I called FaceState (I simply created a driver for both properties and bound them to the positions).
Later the positions of this bone will be used to animate the eyes and mouth.
It's important to keyframe these custom-properties with constant interpolation, and disable simplify in the baking tab when exporting from Blender.

## How does it work?
The main script is the FaceMaterialManager.
It references the FaceMaterial and the face-bones.
The FaceMaterial uses a custom FaceShader, that replicates the original shader created by Wizard.
The FaceMaterialManager script basically looks at the face-bones states and updates the FaceShader accordingly.

The Eyes textures and the Mouths textures must be baked into a texture-atlas before being used in Unity, as using hot-texture-swapping and loading wouldn't be the best performance-wise.
For this reason I duct-taped together a simple texture-packer in python that does it's job. It will simply look in the local directory and paste together all the textures it finds in a square atlas.

The FaceState bone animation data must also be quantized because the interpolation curves are not tangent and constant and this may cause weird and quick textures flashing when updating the face texture.
The FaceAnimationQuantizer quantizes any animation data associated with any bone containing the keyword "FaceState", and it will do so on a pre-asset-import callback.

## Features
  - ✔️ UV Maps alpha-based texture blending
  - ✔️ Animataeble Eye/Mouth texture
  - ✔️ Movement/Scaling of pupils
  - ❌ Animataeble pupils
  - ❌ Rotation of pupils
  - ❌ Distint eye textures
