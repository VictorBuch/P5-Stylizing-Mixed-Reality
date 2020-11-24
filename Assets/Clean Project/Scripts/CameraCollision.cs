using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraCollision : MonoBehaviour
{

    public GameObject frontDoorObjects;
    public GameObject behindDoorObjects;
    public GameObject walls;

    Renderer[] rendFrontDoorObjects;
    Renderer[] rendBehindDoorObjects;
    Renderer[] rendWalls;

    public Camera mainCamera;
    float cameraPosX;

    bool frontOfDoor, behindDoor;
    bool isInPortal = false;

    void Awake()
    {
        rendFrontDoorObjects = frontDoorObjects.GetComponentsInChildren<Renderer>();
        rendBehindDoorObjects = behindDoorObjects.GetComponentsInChildren<Renderer>();
        rendWalls = walls.GetComponentsInChildren<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        cameraPosX = mainCamera.transform.position.x;

        if (cameraPosX > 0)
        {
            frontOfDoor = false;
            behindDoor = true;
        }
        else
        {
            behindDoor = false;
            frontOfDoor = true;
        }
    }


    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("door"))
        {
            if (!isInPortal && frontOfDoor)
            {
                //enter portal and show virtual objects in front of door
                isInPortal = true;

                ToggleVisibilityOn(rendFrontDoorObjects);

            }
            else if (isInPortal && behindDoor)
            {
                //leave portal and hide virtual objects in front of door and show walls
                isInPortal = false;
                ToggleVisibilityOff(rendFrontDoorObjects);
                ToggleVisibilityOn(rendWalls);
            }
            else if (!isInPortal && behindDoor)
            {
                //show walls and virtual objects behind door
                ToggleVisibilityOn(rendWalls);
                ToggleVisibilityOn(rendBehindDoorObjects);
            }
            else if (isInPortal && frontOfDoor)
            {
                //do nothing?
            }
        }
        else if (other.CompareTag("wall"))
        {
            if (!isInPortal && frontOfDoor)
            {
                //hide virtual objects behind door
                ToggleVisibilityOff(rendBehindDoorObjects);
            }
            else if (isInPortal && behindDoor)
            {
                //hide walls
                ToggleVisibilityOff(rendWalls);
            }
            else if (!isInPortal && behindDoor)
            {
                //show walls and objects behind door
                ToggleVisibilityOn(rendWalls);
                ToggleVisibilityOn(rendBehindDoorObjects);
            }
            else if (isInPortal && frontOfDoor)
            {
                //do nothing?
            }
        }
    }

    void ToggleVisibilityOn(Renderer[] rend)
    {
        for (int i = 0; i < rend.Length; i++)
        {
            rend[i].enabled = true;
        }
    }

    void ToggleVisibilityOff(Renderer[] rend)
    {
        for (int i = 0; i < rend.Length; i++)
        {
            rend[i].enabled = false;
        }
    }


}
