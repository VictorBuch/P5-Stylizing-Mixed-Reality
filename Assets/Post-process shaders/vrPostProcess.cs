using UnityEngine;

using UnityEngine.Rendering;

using UnityEngine.Rendering.HighDefinition;

using System;

using UnityEditor;


[Serializable, VolumeComponentMenu("Post-processing/Custom/vrPostProcess")]

public sealed class vrPostProcess : CustomPostProcessVolumeComponent, IPostProcessComponent

{
    [Tooltip("Ativate/Deactivate the cartoon effect")]

    public ClampedIntParameter cartoon_active = new ClampedIntParameter(0, 1, 1);


    [Tooltip("Ativate/Deactivate the water color effect")]

    public ClampedIntParameter wc_active = new ClampedIntParameter(0, 1, 1);


    [Tooltip("Ativate/Deactivate the sketch effect")]

    public ClampedIntParameter sketch_active = new ClampedIntParameter(0, 1, 1);


    [Tooltip("Ativate/Deactivate the Pointilism effect")]

    public ClampedIntParameter pointilism_active = new ClampedIntParameter(0, 1, 1);




    Material m_Material;

    public bool IsActive() => m_Material != null;

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()

    {

        if (Shader.Find("Hidden/Shader/vrPostProcess") != null)

            m_Material = new Material(Shader.Find("Hidden/Shader/vrPostProcess"));

    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)

    {

        if (m_Material == null)

            return;

        m_Material.SetTexture("_InputTexture", source);

        // control variables
        m_Material.SetInt("_CartoonActive", cartoon_active.value);  
        m_Material.SetInt("_WaterColorActive", wc_active.value);
        m_Material.SetInt("_SketchActive", sketch_active.value);
        m_Material.SetInt("_PointilismActive", pointilism_active.value);
        

        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);

}
