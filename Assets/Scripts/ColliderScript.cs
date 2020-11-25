﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColliderScript : MonoBehaviour
{
    public GameObject outsideCollider;
    public GameObject insideCollider;
    public GameObject door;
    public GameObject walls;
    public GameObject hiddenEnvironment;
    public GameObject vrOnlyEnvironment;
    public GameObject camera;
    public GameObject key;
    public GameObject grabber;
    public GameObject center;
    public Material grabberMaterial;
    public bool doorEntered;
    public bool inVr = false;
    public bool inVrSide = false;
    public bool insideColliding;
    public bool outsideColliding;
    public bool grabbing = false;
    public bool grabbableIsNear = false;
    public float turnSpeed = 0.5f;

    // Start is called before the first frame update
    void Start()
    {
        grabberMaterial.SetColor("_Color", Color.red);

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey("w"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0.05f, 0f, 0f);
        }

        if (Input.GetKey("s"))
        {
            camera.GetComponent<Transform>().position += new Vector3(-0.05f, 0f, 0f);
        }

        if (Input.GetKey("a"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0f, 0f, 0.05f);
        }

        if (Input.GetKey("d"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0f, 0f, -0.05f);
        }
        if (Input.GetKey("q"))
        {
          camera.GetComponent<Transform>().Rotate(0.0f, -turnSpeed, 0.0f);
        }
        if (Input.GetKey("e"))
        {
          camera.GetComponent<Transform>().Rotate(0.0f, turnSpeed, 0.0f);
        }

        //FOR GRABBING
        if (Input.GetAxis("XRI_Right_Trigger") > 0.01f)
        {
            grabKey();
            grabberMaterial.SetColor("_Color", Color.blue);
        }

        if (Input.GetAxis("XRI_Right_Trigger") < 0.01f)
        {
            unGrabKey();
            grabberMaterial.SetColor("_Color", Color.blue);
        }

    }

    void enableVST()
    {
        hiddenEnvironment.SetActive(true);
        //Debug.Log("VST disbled LMAO");
    }

    void disableVST()
    {
        hiddenEnvironment.SetActive(false);
        //Debug.Log("VST disabled LOL");
    }

    public void collide(string id,string collidingObjectId)
    {
        //Debug.Log("collision detected");
        if(id == "outside" && collidingObjectId == "Player")
        {
            if (doorEntered) { inVr = false; walls.SetActive(true); vrOnlyEnvironment.SetActive(false); }

            if (!inVr) { enableVST(); }

            inVrSide = false;

            outsideColliding = true;
            //Debug.Log("outside collision");
        } else if (id == "inside" && collidingObjectId == "Player")
        {

            if (doorEntered) { inVr = true; walls.SetActive(false); vrOnlyEnvironment.SetActive(true); }

            if (!inVr) { disableVST(); }

            inVrSide = true;

            insideColliding = true;
            Debug.Log("inside collision");
        }
        if(id == "door" && collidingObjectId == "Player")
        {
            doorEntered = true;
            Debug.Log("door entered");
        }

        if(id == "KeyHole" && collidingObjectId == "Key")
        {
            Debug.Log("YOURE WINNER");
        }

        if (id == "Grabber" && collidingObjectId == "Key") 
        {
            grabbableIsNear = true;
        }
    }

    public void uncollide(string id, string collidingObjectId)
    {
        if (id == "door" && collidingObjectId == "Player")
        {

            doorEntered = false;
            Debug.Log("Door left");
        }

        if (id == "inside" && collidingObjectId == "Player")
        {
            insideColliding = false;
            if (outsideColliding && !doorEntered) { if (!inVr) { enableVST(); } inVrSide = false; }
        }
        if (id == "outside" && collidingObjectId == "Player")
        {
            outsideColliding = false;
            if (insideColliding && !doorEntered) { if (!inVr) { disableVST(); } inVrSide = true; }
        }

        if (id == "Grabber" && collidingObjectId == "Key")
        {
            grabbableIsNear = false;
        }
    }

    private void grabKey()
    {
        grabbing = true;
        key.GetComponent<Rigidbody>().isKinematic = true;
        key.transform.parent = grabber.transform;
    }

    private void unGrabKey()
    {
        grabbing = false;
        key.GetComponent<Rigidbody>().isKinematic = false;
        key.transform.parent = center.transform;
    }


}
