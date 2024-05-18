using System;
using UnityEngine;

namespace Animation
{
    /// <summary>
    /// Provides an astraction to the creation and usage of a texture atlas.
    /// </summary>
    class TextureAtlasInfo
    {
        public TextureAtlasInfo(Vector2 textureSize, Vector2 cellSize, string shaderUpdateKeyword, Action<string, Vector2> shaderUpdateCallback)
        {
            this._textureSize = textureSize;
            this._cellSize = cellSize;
            this._shaderUpdateCallback = shaderUpdateCallback;
            this._shaderUpdateKeyword = shaderUpdateKeyword;

            int size;
            if (int.TryParse((_textureSize.x / cellSize.x).ToString(), out size))
            {
                _gridSize = size;
            }
            else
            {
                Debug.LogError("The grid size is a float instead of an int!\nCheck that the cell size is correct.");
                _gridSize = 1;
            }

            _uvsScalingFactor = 1.0f / _gridSize;
        }

        private Vector2 _textureSize;
        private Vector2 _cellSize;
        private Action<string, Vector2> _shaderUpdateCallback;

        private int _gridSize;

        private string _shaderUpdateKeyword;

        private float _uvsScalingFactor;
        public float UVSScalingFactor => _uvsScalingFactor;

        /// <summary>
        /// Offsets the setted UV maps to the index of the texture in the atlas.
        /// </summary>
        /// <param name="textureIndex">The texture index in the atlas</param>
        public void UpdateActiveTexture(int textureIndex)
        {
            int ySteps = Mathf.FloorToInt(textureIndex / _gridSize);
            int xSteps = textureIndex % _gridSize;

            float yOffset = (ySteps * _cellSize.y) / _textureSize.y;
            float xOffset = (xSteps * _cellSize.x) / _textureSize.x;

            _shaderUpdateCallback(_shaderUpdateKeyword, new Vector2(xOffset, yOffset));
        }
    }

    /// <summary>
    /// Controls the FaceMaterial shader to animate the face properties.
    /// </summary>
    public class FaceMaterialManager : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Material _faceMaterial;
        [Space]
        [Header("Bones")]
        [SerializeField] private Transform _UVPupilBaseBone;
        [Space]
        [SerializeField] private Transform _UVPupilLBone;
        [SerializeField] private Transform _UVPupilRBone;
        [SerializeField] private Transform _UVPupilTransformBone;
        [SerializeField] private Vector2 _UVOffset;
        [SerializeField] private Transform _faceStateBone;
        [Space]
        [Header("Textures")]
        [SerializeField] private Texture _eyeStatesTexture;
        [SerializeField] private Vector2 _eyeStatesCellSize;
        private TextureAtlasInfo _eyeStatesInfo;
        [Space]
        [SerializeField] private Texture _pupilLTexture;
        [SerializeField] private Texture _pupilRTexture;
        [Space]
        [SerializeField] private Texture _mouthStatesTexture;
        [SerializeField] private Vector2 _mouthStatesCellSize;
        private TextureAtlasInfo _mouthStatesInfo;

        const string EYETEXTURE = "_EyeTexture";
        const string UVEYESCALE = "_UVEyeScale";
        const string UVEYEOFFSET = "_UVEyeOffset";

        const string MOUTHTEXTURE = "_MouthTexture";
        const string UVMOUTHSCALE = "_UVMouthScale";
        const string UVMOUTHOFFSET = "_UVMouthOffset";

        const string PUPILTEXTUREL = "_PupilTextureL";
        const string PUPILTEXTURER = "_PupilTextureR";
        const string UVPUPILOFFSETL = "_UVPupilOffsetL";
        const string UVPUPILOFFSETR = "_UVPupilOffsetR";
        const string UVPUPILSCALE = "_UVPupilScale";

        /// <summary>
        /// Updates the shader even in the inspector for proper model visualization.
        /// </summary>
        private void OnValidate()
        {
            if (_pupilLTexture != null)
                _faceMaterial.SetTexture(PUPILTEXTUREL, _pupilLTexture);
            if (_pupilRTexture != null)
                _faceMaterial.SetTexture(PUPILTEXTURER, _pupilRTexture);

            if (_eyeStatesTexture != null)
            {
                _faceMaterial.SetTexture(EYETEXTURE, _eyeStatesTexture);

                _eyeStatesInfo = new(new Vector2(_eyeStatesTexture.width, _eyeStatesTexture.height),
                                     _eyeStatesCellSize,
                                     UVEYEOFFSET,
                                     ShaderUpdateCallback);

                _faceMaterial.SetFloat(UVEYESCALE, _eyeStatesInfo.UVSScalingFactor);
            }

            if (_mouthStatesTexture != null)
            {
                _faceMaterial.SetTexture(MOUTHTEXTURE, _mouthStatesTexture);

                _mouthStatesInfo = new(new Vector2(_mouthStatesTexture.width, _mouthStatesTexture.height),
                         _mouthStatesCellSize,
                         UVMOUTHOFFSET,
                         ShaderUpdateCallback);

                _faceMaterial.SetFloat(UVMOUTHSCALE, _mouthStatesInfo.UVSScalingFactor);
            }
        }

        /// <summary>
        /// Animates the face shader properties.
        /// </summary>
        private void LateUpdate()
        {
            /// PUPILS
            // Animate pupils by their relative position to the UVPupilBaseBone and offset them
            Vector2 offsetL = (Vector2)(_UVPupilLBone.position - _UVPupilBaseBone.position) * new Vector2(1, -1) + _UVOffset;
            Vector2 offsetR = (Vector2)(_UVPupilRBone.position - _UVPupilBaseBone.position) * new Vector2(1, -1) + _UVOffset * new Vector2(-1, 1);

            // Update the face shader pupils offsets
            _faceMaterial.SetVector(UVPUPILOFFSETL, offsetL);
            _faceMaterial.SetVector(UVPUPILOFFSETR, offsetR);

            // Update pupils scaling based on the pupil transform bone
            _faceMaterial.SetFloat(UVPUPILSCALE, _UVPupilTransformBone.localScale.y);

            /// EYES
            // Get eyetextureindex value from the x location of the facestatebone
            _eyeStatesInfo.UpdateActiveTexture(Mathf.RoundToInt(Mathf.Abs(_faceStateBone.localPosition.x)));

            /// MOUTH
            // Get mouthtextureindex value from the y location of the facestatebone
            _mouthStatesInfo.UpdateActiveTexture(Mathf.RoundToInt(Mathf.Abs(_faceStateBone.localPosition.y)));
        }

        /// <summary>
        /// Resets all the face shader properties.
        /// </summary>
        private void OnDestroy()
        {
            _faceMaterial.SetVector(UVPUPILOFFSETL, Vector2.zero);
            _faceMaterial.SetVector(UVPUPILOFFSETR, Vector2.zero);

            _faceMaterial.SetFloat(UVPUPILSCALE, 1);

            _eyeStatesInfo.UpdateActiveTexture(0);
            _mouthStatesInfo.UpdateActiveTexture(0);
        }

        /// <summary>
        /// Callback used by the TextureAtlasInfo instances to update the face shader UVs.
        /// </summary>
        /// <param name="keyword">Keyword assigned to the TextureAtlasInfo for the UV to update</param>
        /// <param name="offset">UV maps offset</param>
        public void ShaderUpdateCallback(string keyword, Vector2 offset)
        {
            _faceMaterial.SetVector(keyword, offset);
        }
    }
}