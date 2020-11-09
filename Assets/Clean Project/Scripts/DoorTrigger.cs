using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DoorTrigger : MonoBehaviour
{

    public GameObject stuffOutsideEnv;
    Renderer[] rend;
    bool inPortal = false;

    void OnTriggerEnter(Collider other)
    {

        //Renderer rend = stuff.GetComponent<Renderer>();
        rend = stuffOutsideEnv.GetComponentsInChildren<Renderer>();

        Debug.Log("enter portal");

        if (!inPortal)
        {
            inPortal = true;
            Debug.Log(inPortal);

            for (int i = 0; i < rend.Length; i++)
            {
                rend[i].enabled = false;
            }
           
        }
        else
        {
            inPortal = false;
            Debug.Log("outPortal");

            for (int i = 0; i < rend.Length; i++)
            {
                rend[i].enabled = true;
            }

        }

    }

    void OnTriggerStay(Collider other)
    {
        Debug.Log("inside portal");
    }
    void OnTriggerExit(Collider other)
    {
        Debug.Log("leave portal");
    }
}
