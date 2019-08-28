using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class GradientMapGenerator : MonoBehaviour
{
    [Header("Gradient map parameters")]
    public Vector2Int gradientMapDimensions = new Vector2Int(128, 32);
    public Gradient gradient;

    [Header("Enable testing")]
    public bool testing = false;

    private SpriteRenderer spriteRenderer;
    private Material material;

    [HideInInspector]
    public Texture2D texture;

    public static int totalMaps = 0;

    private void OnEnable()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        if (spriteRenderer == null)
        {
            Debug.LogWarning("No sprite renderer on this game object! Removing GradientMapper");
            DestroyImmediate(this);
        }
        else
        {
            material = spriteRenderer.sharedMaterial;
        }
    }

   public void CreateGradient()
    {
        texture = new Texture2D(gradientMapDimensions.x, gradientMapDimensions.y);
        texture.wrapMode = TextureWrapMode.Clamp;
        for (int x = 0; x < gradientMapDimensions.x; x++)
        {
            Color color = gradient.Evaluate((float)x / (float)gradientMapDimensions.x);
            for (int y = 0; y < gradientMapDimensions.y; y++)
            {
                texture.SetPixel(x, y, color);
            }
        }
        texture.Apply();
        if (material.HasProperty("_GradientMap"))
        {
            material.SetTexture("_GradientMap", texture);
        }
    }

    void Update()
    {
        if (testing)
        {
            texture = new Texture2D(gradientMapDimensions.x, gradientMapDimensions.y);
            texture.wrapMode = TextureWrapMode.Clamp;
            for (int x = 0; x < gradientMapDimensions.x; x++)
            {
                Color color = gradient.Evaluate((float)x / (float)gradientMapDimensions.x);
                for (int y = 0; y < gradientMapDimensions.y; y++)
                {
                    texture.SetPixel(x, y, color);
                }
            }
            texture.Apply();
            if (material.HasProperty("_GradientMap"))
            {
                material.SetTexture("_GradientMap", texture);
            }
        }
    }

}

#if UNITY_EDITOR
[CustomEditor(typeof(GradientMapGenerator))]
public class GradientMapperEditor : Editor
{

    public override void OnInspectorGUI()
    {
        GradientMapGenerator gradientGenerator = target as GradientMapGenerator;
        DrawDefaultInspector();
        if (gradientGenerator.testing)
        {
            EditorGUILayout.HelpBox("Testing is active.", MessageType.Warning, true);
        }
        if (GUILayout.Button("Make Gradient Map"))
        {
            gradientGenerator.testing = false;
            gradientGenerator.CreateGradient();
            if (!AssetDatabase.IsValidFolder("Assets/GradientMaps"))
            {
                AssetDatabase.CreateFolder("Assets/", "GradientMaps");
                AssetDatabase.SaveAssets();
            }
            if (!Directory.Exists(Application.dataPath + "GradientMaps"))
            {
                Directory.CreateDirectory(Application.dataPath + "/GradientMaps/");
                GradientMapGenerator.totalMaps = 0;
            }
            else
            {
                GradientMapGenerator.totalMaps = Directory.GetFiles(Application.dataPath + "/GradientMaps/").Length;
            }

            byte[] bytes = gradientGenerator.texture.EncodeToPNG();
            while (File.Exists(Application.dataPath + "/GradientMaps/gradient_map_" + GradientMapGenerator.totalMaps.ToString() + ".png"))
            {
                GradientMapGenerator.totalMaps++;
            }
            File.WriteAllBytes(Application.dataPath + "/GradientMaps/gradient_map_" + GradientMapGenerator.totalMaps.ToString() + ".png", bytes);
            AssetDatabase.Refresh();

            Debug.Log("Gradient map saved!");
        }
    }
}
#endif
