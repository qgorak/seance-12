<?php

namespace App\Controller;


use App\Entity\Order;
use App\Entity\Orderdetail;
use App\Entity\Product;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Annotation\Route;


class MainController extends AbstractController
{
    #[Route('/', name: 'app_main')]
    public function index()
    {
        return $this->render('order/index.html.twig', array(
        ));
    }

    #[Route('/search', name: 'search')]
    public function search(ManagerRegistry $doctrine){
        $repository = $doctrine->getRepository(Product::class);
        return $this->render('order/search.html.twig', array(
        ));

    }

    #[Route('/orders', name: 'orders')]
    public function orders(ManagerRegistry $doctrine)
    {
        $repository = $doctrine->getRepository(Order::class);
        $orders = $repository->findAll();
        return $this->render('order/order.html.twig', array(
        "orders"=>$orders));

    }


    #[Route('/prepare', name: 'prepare')]
    public function prepare(ManagerRegistry $doctrine, EntityManagerInterface $em)
    {
        $repository = $doctrine->getRepository(Orderdetail::class);
        foreach ($orders as $order){
            $order->setPrepared(0);
        }
        $em->flush();

    }


}
