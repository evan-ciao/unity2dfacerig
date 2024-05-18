using UnityEngine;
using UnityEditor;

namespace EditorUtility
{
    /// <summary>
    /// This utiliy class enables constant interpolation on
    /// any FaceState bone found when importing new animation data.
    /// </summary>
    public class FaceAnimationQuantizer : AssetPostprocessor
    {
        private void OnPostprocessAnimation(GameObject root, AnimationClip clip)
        {
            var curveBindings = AnimationUtility.GetCurveBindings(clip);
            foreach (var curveBinding in curveBindings)
            {
                if (((Transform)(AnimationUtility.GetAnimatedObject(root, curveBinding))).name.Contains("FaceState"))
                {
                    Debug.Log($"AnimationQuantizer Found FaceState bone {AnimationUtility.GetAnimatedObject(root, curveBinding)} in {clip.name}");
                    var curve = AnimationUtility.GetEditorCurve(clip, curveBinding);
                    for (int i = 0; i < curve.keys.Length; i++)
                    {
                        curve.keys[i].inWeight = 0;
                        curve.keys[i].outWeight = 0;
                        curve.keys[i].inTangent = 0;
                        curve.keys[i].outTangent = 0;
                        curve.keys[i].weightedMode = WeightedMode.None;
                        AnimationUtility.SetKeyLeftTangentMode(curve, i, AnimationUtility.TangentMode.Constant);
                        AnimationUtility.SetKeyRightTangentMode(curve, i, AnimationUtility.TangentMode.Constant);
                    }
                    AnimationUtility.SetEditorCurve(clip, curveBinding, curve);
                }
            }
        }
    }
}