<?php
namespace controllers;


/**
 * Controller IndexController
 */
class IndexController extends ControllerBase {

	    /**
     *
     * @autowired
     * @var OrderDetailsDAOLoader
     */
    private $loader;

	  /**
     *
     * @param \services\DAO\OrderDetailsDAOLoader $loader
     */
    public function setLoader($loader) {
        $this->loader = $loader;
    }

	public function index() {
		$this->loadView('/main/vMenu.html');
	}





}
