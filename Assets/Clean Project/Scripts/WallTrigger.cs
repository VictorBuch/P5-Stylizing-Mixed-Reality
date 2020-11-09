using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WallTrigger : MonoBehaviour
{
    public GameObject stuffInsideEnv;
    Renderer[] rend;
    bool inPortal = false;

    void OnTriggerEnter(Collider other)
    {

        //Renderer rend = stuff.GetComponent<Renderer>();
        rend = stuffInsideEnv.GetComponentsInChildren<Renderer>();

        Debug.Log("enter wall");

        if (!inPortal)
        {

            for (int i = 0; i < rend.Length; i++)
            {
                if (rend[i].enabled == true)
                    rend[i].enabled = false;
                else
                    rend[i].enabled = true;
            }

        }
        else
        {

            for (int i = 0; i < rend.Length; i++)
            {
                rend[i].enabled = true;
            }

        }

    }

    void OnTriggerStay(Collider other)
    {
        Debug.Log("inside wall");
    }
    void OnTriggerExit(Collider other)
    {
        Debug.Log("leave wall");
    }
}
