using UnityEditor;
using UnityEngine;

namespace Sunflower.Editor
{
    public sealed class IslandArtImporter : AssetPostprocessor
    {
        void OnPreprocessTexture()
        {
            if(!assetPath.StartsWith("Assets/Resources/IslandUI/"))return;
            var importer=(TextureImporter)assetImporter;
            importer.textureType=TextureImporterType.Default;
            importer.alphaSource=TextureImporterAlphaSource.FromInput;
            importer.alphaIsTransparency=true;
            importer.mipmapEnabled=false;
            importer.npotScale=TextureImporterNPOTScale.None;
            importer.wrapMode=TextureWrapMode.Clamp;
            importer.filterMode=FilterMode.Bilinear;
            importer.maxTextureSize=assetPath.Contains("/Drink_")?256:4096;
            importer.textureCompression=TextureImporterCompression.Uncompressed;
        }
    }
}
