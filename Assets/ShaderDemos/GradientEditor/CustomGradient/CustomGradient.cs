using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[System.Serializable]
public struct ColorKey
{
    [SerializeField] Color col;
    public Color Col { get { return col; } }

    [SerializeField] float time;
    public float Time { get { return time; } }

    // constructor
    public ColorKey(Color col, float time)
    {
        this.col = col;
        this.time = time;
    }
}

public enum BlendMode
{
    Linear,
    Discrete
};


[System.Serializable]
public class CustomGradient
{
    public BlendMode blendMode;

    [SerializeField] List<ColorKey> keys = new List<ColorKey>();

    public bool randomizeColor;

    public CustomGradient()
    {
        AddColorKey(Color.white,0);
        AddColorKey(Color.black,1);
    }

    public int KeyCount { get { return keys.Count; } }
    public ColorKey GetKey(int i)
    {
        return keys[i];
    }
    public int AddColorKey(Color col, float time)
    {
        ColorKey newKey = new ColorKey(col, time);
        for (int i = 0; i < keys.Count; i++)
        {
            if (newKey.Time < keys[i].Time)
            {
                keys.Insert(i, newKey);
                return i;
            }
        }
        keys.Add(newKey); // Add key to the end of the list if the key is not return yet
        return keys.Count - 1;
    }

    public void RemoveKey(int index)
    {
        if (keys.Count >= 2)
        {
            keys.RemoveAt(index);
        }
    }

    public int UpdateKeyTime(int index, float time)
    {
        Color col = keys[index].Col;
        RemoveKey(index);
        return AddColorKey(col, time);
    }
    public void UpdateKeyColor(int index, Color col)
    {
        keys[index] = new ColorKey(col, keys[index].Time);
    }

    public Color Evaluate(float time)
    {
        ColorKey keyLeft = keys[0];
        ColorKey keyright = keys[keys.Count - 1];
        for (int i = 0; i < keys.Count; i++)
        {
            if (keys[i].Time < time  )
            {
                keyLeft = keys[i];
            }
            if (keys[i].Time > time)
            {
                keyright = keys[i];
                break;
            }
        }

        if (blendMode == BlendMode.Linear)
        {
            float blendTime = Mathf.InverseLerp(keyLeft.Time, keyright.Time, time);
            return Color.Lerp(keyLeft.Col, keyright.Col, blendTime);
        }
        return keyright.Col;

    }

    public Texture2D GetTexture(int width)
    {
        Texture2D tex = new Texture2D(width, 1);
        Color[] cols = new Color[width];
        for (int i = 0; i < width; i++)
        {
            cols[i] = Evaluate((float)i / (width - 1));
        }

        tex.SetPixels(cols);
        tex.Apply();
        return tex;
    }


}
