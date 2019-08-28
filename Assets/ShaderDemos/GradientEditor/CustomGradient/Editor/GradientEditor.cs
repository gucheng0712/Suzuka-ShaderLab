using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class GradientEditor : EditorWindow
{
    CustomGradient gradient;
    const int BORDER_SIZE = 10;
    const int KEY_WIDTH = 10;
    const int KEY_HEIGHT = 20;

    Rect gradientPreviewRect;
    Rect[] keyRects;
    bool mouseIsDownOverKey;
    int selectedKeyIndex;
    bool needsRepaint;

    private void OnGUI()
    {
        Draw();
        HandleInput();

        if (needsRepaint)
        {
            needsRepaint = false;
            Repaint();
        }
    }

    private void Draw()
    {
        gradientPreviewRect = new Rect(BORDER_SIZE, BORDER_SIZE, position.width - BORDER_SIZE * 2, 25);
        GUI.DrawTexture(gradientPreviewRect, gradient.GetTexture((int)gradientPreviewRect.width));

        keyRects = new Rect[gradient.KeyCount];
        for (int i = 0; i < gradient.KeyCount; i++)
        {
            ColorKey key = gradient.GetKey(i);
            float keyX = gradientPreviewRect.x + gradientPreviewRect.width * key.Time - KEY_WIDTH / 2f;
            float keyY = gradientPreviewRect.yMax + BORDER_SIZE;
            Rect keyRect = new Rect(keyX, keyY, KEY_WIDTH, KEY_HEIGHT);

            if (i == selectedKeyIndex)
            {
                EditorGUI.DrawRect(new Rect(keyRect.x - 2, keyRect.y - 2, keyRect.width + 4, keyRect.height + 4), Color.black);
            }
            EditorGUI.DrawRect(keyRect, key.Col);
            keyRects[i] = keyRect;
        }

        Rect settingsRect = new Rect(BORDER_SIZE, keyRects[0].yMax + BORDER_SIZE, position.width - BORDER_SIZE * 2, position.height - BORDER_SIZE * 9);
        GUILayout.BeginArea(settingsRect);
        EditorGUI.BeginChangeCheck();
        Color newCol = EditorGUILayout.ColorField(gradient.GetKey(selectedKeyIndex).Col);
        if (EditorGUI.EndChangeCheck())
        {
            gradient.UpdateKeyColor(selectedKeyIndex, newCol);
        }
        gradient.blendMode = (BlendMode)EditorGUILayout.EnumPopup("Blend Mode", gradient.blendMode);
        gradient.randomizeColor = EditorGUILayout.Toggle("Randmize Color", gradient.randomizeColor);
        GUILayout.EndArea();
    }

    void HandleInput()
    {
        Event guiEvent = Event.current;
        if (guiEvent.type == EventType.MouseDown && guiEvent.button == 0)
        {
            for (int i = 0; i < keyRects.Length; i++)
            {
                if (keyRects[i].Contains(guiEvent.mousePosition))
                {
                    mouseIsDownOverKey = true;
                    selectedKeyIndex = i;
                    needsRepaint = true;
                    break;
                }
            }

            if (!mouseIsDownOverKey)
            {
                Color randomColor = new Color(Random.value, Random.value, Random.value);
                float keyTime = Mathf.InverseLerp(gradientPreviewRect.x, gradientPreviewRect.xMax, guiEvent.mousePosition.x);
                Color interpolatedColor = gradient.Evaluate(keyTime);
                selectedKeyIndex = gradient.AddColorKey(gradient.randomizeColor ? randomColor : interpolatedColor, keyTime);
                mouseIsDownOverKey = true;
                needsRepaint = true;
            }
        }

        if (guiEvent.type == EventType.MouseUp && guiEvent.button == 0)
        {
            mouseIsDownOverKey = false;
        }
        if (mouseIsDownOverKey && guiEvent.type == EventType.MouseDrag && guiEvent.button == 0)
        {
            float keyTime = Mathf.InverseLerp(gradientPreviewRect.x, gradientPreviewRect.xMax, guiEvent.mousePosition.x);
            selectedKeyIndex = gradient.UpdateKeyTime(selectedKeyIndex, keyTime);
            needsRepaint = true;
        }

        if (guiEvent.keyCode == KeyCode.Backspace && guiEvent.type == EventType.KeyDown)
        {
            gradient.RemoveKey(selectedKeyIndex);
            if (selectedKeyIndex >= gradient.KeyCount)
            {
                selectedKeyIndex--;
            }
            needsRepaint = true;
        }
    }

    public void SetGradient(CustomGradient gradient)
    {
        this.gradient = gradient;
    }

    private void OnEnable()
    {
        titleContent.text = "Gradient Editor";
        position.Set(position.x, position.y, 400, 150);
        minSize = new Vector2(200, 150);
        maxSize = new Vector2(1920,150);
    }

    private void OnDisable()
    {
        UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(UnityEngine.SceneManagement.SceneManager.GetActiveScene());
    }
}
