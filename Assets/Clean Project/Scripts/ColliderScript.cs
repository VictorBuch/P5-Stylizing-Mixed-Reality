using System.Collections;
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
    public bool doorEntered;
    public bool inVr = false;
    public bool inVrSide = false;
    public bool insideColliding;
    public bool outsideColliding;
    public float turnSpeed = 0.5f;

    // Start is called before the first frame update
    void Start()
    {


    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey("w"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0.1f, 0f, 0f);
        }

        if (Input.GetKey("s"))
        {
            camera.GetComponent<Transform>().position += new Vector3(-0.1f, 0f, 0f);
        }

        if (Input.GetKey("a"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0f, 0f, 0.1f);
        }

        if (Input.GetKey("d"))
        {
            camera.GetComponent<Transform>().position += new Vector3(0f, 0f, -0.1f);
        }
        if (Input.GetKey("q"))
        {
          camera.GetComponent<Transform>().Rotate(0.0f, -turnSpeed, 0.0f);
        }
        if (Input.GetKey("e"))
        {
          camera.GetComponent<Transform>().Rotate(0.0f, turnSpeed, 0.0f);
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

    public void collide(string id)
    {
        //Debug.Log("collision detected");
        if(id == "outside")
        {
            if (doorEntered) { inVr = false; walls.SetActive(true); vrOnlyEnvironment.SetActive(false); }

            if (!inVr) { enableVST(); }

            inVrSide = false;

            outsideColliding = true;
            //Debug.Log("outside collision");
        } else if (id == "inside")
        {

            if (doorEntered) { inVr = true; walls.SetActive(false); vrOnlyEnvironment.SetActive(true); }

            if (!inVr) { disableVST(); }

            inVrSide = true;

            insideColliding = true;
            //Debug.Log("inside collision");
        }
        if(id == "door")
        {
            doorEntered = true;

        }
    }

    public void uncollide(string id)
    {
        if (id == "door")
        {

            doorEntered = false;
        }

        if (id == "inside")
        {
            insideColliding = false;
            if (outsideColliding && !doorEntered) { enableVST(); inVrSide = false; }
        }
        if (id == "outside")
        {
            outsideColliding = false;
            if (insideColliding && !doorEntered) { disableVST(); inVrSide = true; }
        }
    }


}
