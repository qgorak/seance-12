<?php

namespace controllers;

use models\Order;
use models\Orderdetail;
use models\Product;
use services\DAO\OrderDetailsDAOLoader;
use Ubiquity\controllers\Router;
use Ubiquity\orm\DAO;
use Ubiquity\utils\http\URequest;

/**
 * Controller OrderController
 * @route('order','inherited'=>true,'automated'=>true)
 * @property \Ajax\php\ubiquity\JsUtils $jquery
 */
class OrderController extends \controllers\ControllerBase
{

    /**
     *
     * @autowired
     * @var OrderDetailsDAOLoader
     */
    private $loader;

    public function initialize()
    {
        parent::initialize();
        $this->setLoader(new OrderDetailsDAOLoader());
    }

    /**
     *
     * @param \services\DAO\OrderDetailsDAOLoader $loader
     */
    public function setLoader($loader)
    {
        $this->loader = $loader;
    }

    public function index()
    {

    }

    /**
     * @route('search','name'=>'search',methods: ['get','post']))
     */
    public function search(){
        $search = URequest::post('q');
        $products = DAO::getAll(Product::class,'MATCH(comments) AGAINST(? IN NATURAL LANGUAGE MODE)',false,[$search]);
        $this->jquery->renderView('OrderController/products.html', [
            "products" => $products
        ]);

    }

    /**
     * @get('orders','name'=>'orders')
     */
    public function orders()
    {
        $orders = $this->loader->getAll();
        $this->jquery->exec('window.arrayOrders = [];', true);
        $this->jquery->execOn('change', '.validate', '
        if($.inArray(event.target.getAttribute("data-ajax"), window.arrayOrders )<0) {
        //add to array
            window.arrayOrders .push(event.target.getAttribute("data-ajax")); // <- basic JS see Array.push
        } else {
        //remove from array
         window.arrayOrders.splice($.inArray(event.target.getAttribute("data-ajax"), window.arrayOrders ),1); // <- basic JS see Array.splice
        };
        if(window.arrayOrders.length>0){
            $("#send").removeClass("hidden");
        }else{
            $("#send").addClass("hidden");
        }
        ');
        $this->jquery->postOnClick('#send','/OrderController/prepare','{ids:window.arrayOrders}','#load');
        $this->jquery->renderView('OrderController/orders.html', [
            "orders" => $orders
        ]);
    }

    /**
     * @post('prepare','name'=>'prepare')
     */
    public function prepare()
    {
        $orders=[];
        foreach(URequest::getDatas()['ids'] as $ids){
            $composites = json_decode($ids);
            $orders[]='('.$composites[0].','.$composites[1].')';
        };
        $db = DAO::getDatabase();
        $db->query("UPDATE orderdetail set `prepared`=NOT `prepared` WHERE (idOrder, idProduct) in(
            ".join(',',$orders)."
       );");
        return $this->orders();

    }

    /**
     * @get('getBasket/{id}','name'=>'basket')
     */
    public function getBasket($id)
    {
        $basket = $this->loader->getBasket($id);
        $this->jquery->postOnClick('#send','/OrderController/validate','{id:event.target.getAttribute("data-ajax")}',"#load");
        $this->jquery->renderView('OrderController/basket.html', [
            "basket" => $basket
        ]);
    }

    /**
     * @post('validate','name'=>'validate')
     */
    public function validate()
    {
        $order = new Order();
        $id=(int)URequest::getRealPOST()['id'];
        $basket = $this->loader->getBasket($id);
        $orderDetails=[];
        $totalQuantity=0;
        $price =  0;
        $missing=0;
        foreach ($basket->getBasketdetails() as $details){
            $product = $details->getProduct();
            $orderDetail= new Orderdetail();
            $orderDetail->setOrder($order);
            $orderDetail->setPrepared(0);
            $orderDetail->setQuantity($details->getQuantity());
            $totalQuantity+=$details->getQuantity();

            if ($product->getStock()<$orderDetail->getQuantity()){
                $missing+=$product->getStock()-$orderDetail->getQuantity();
            }
            $product->setStock($product->getStock()-$orderDetail->getQuantity());
            $price+=$product->getPrice()*$details->getQuantity();
            $orderDetail->setIdProduct($product->getId());
            DAO::toUpdate($product);
            $orderDetails[]=$orderDetail;
        }
        DAO::flushUpdates();
        $order->setUser(1);
        $order->setStatus('created');
        $order->setDateCreation(\date_create()->format('Y-m-d H:i:s'));
        $order->setAmount($price);
        $order->setToPay(0);
        $order->setItemsNumber($totalQuantity);
        $order->setMissingNumber($missing);
        $order->setOrderdetails($orderDetails);
        DAO::save($order,true);
        foreach ($orderDetails as $orderDetail) {
            $orderDetail->setIdOrder($order->getId());
            DAO::save($orderDetail);
        }
        $this->jquery->postOnClick('#validate','/OrderController/validate','{id:event.target.getAttribute("data-ajax")}');
        $this->jquery->renderView('OrderController/valid.html', [
            "order" => $orderDetails
        ]);

    }

    /**
     * @get('get/{id}','name'=>'order.details')
     */
    public function get($id)
    {
        $orderDetails = $this->loader->get($id);
        $this->jquery->renderView('OrderController/index.html', [
            "order" => $orderDetails
        ]);
    }


}
