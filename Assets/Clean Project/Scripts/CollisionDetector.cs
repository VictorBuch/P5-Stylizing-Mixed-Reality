using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionDetector : MonoBehaviour
{
    public GameObject colliderScriptObject;
    public string id;
    private ColliderScript colliderScript;

    // Start is called before the first frame update
    void Start()
    {
        colliderScript = colliderScriptObject.GetComponent<ColliderScript>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnTriggerEnter(Collider collider)
    {
        colliderScript.collide(id);
    }

    private void OnTriggerExit(Collider collider)
    {
        colliderScript.uncollide(id);
    }
}
