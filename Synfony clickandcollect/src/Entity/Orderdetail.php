<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
/**
 * Orderdetail
 *
 * @ORM\Table(name="`orderdetail`", indexes={@ORM\Index(name="idUser", columns={"idUser"}), @ORM\Index(name="idEmployee", columns={"idEmployee"}), @ORM\Index(name="idTimeslot", columns={"idTimeslot"})})
 * @ORM\Entity
 */
class Orderdetail
{
    /** @ORM\Id @ORM\ManyToOne(targetEntity="Order")
     * @ORM\JoinColumn(name="idOrder", referencedColumnName="id")
     */
    private $order;

    /** @ORM\Id @ORM\ManyToOne(targetEntity="Product", inversedBy="orderdetails")
     * @ORM\JoinColumn(name="idProduct", referencedColumnName="id")
     */
    private $product;

    /**
     * @var int
     *
     * @ORM\Column(name="quantity", type="integer", nullable=false)
     */
    private $quantity;

    /**
     * @var bool
     *
     * @ORM\Column(name="prepared", type="boolean")
     */
    private $prepared;

    /**
     * @return int
     */
    public function getQuantity(): int
    {
        return $this->quantity;
    }

    /**
     * @param int $quantity
     */
    public function setQuantity(int $quantity): void
    {
        $this->quantity = $quantity;
    }

    /**
     * @return mixed
     */
    public function getOrder()
    {
        return $this->order;
    }

    /**
     * @param mixed $order
     */
    public function setOrder($order): void
    {
        $this->order = $order;
    }

    /**
     * @return mixed
     */
    public function getProduct()
    {
        return $this->product;
    }

    /**
     * @param mixed $product
     */
    public function setProduct($product): void
    {
        $this->product = $product;
    }

    /**
     * @return bool
     */
    public function isPrepared(): bool
    {
        return $this->prepared;
    }

    /**
     * @param bool $prepared
     */
    public function setPrepared(bool $prepared): void
    {
        $this->prepared = $prepared;
    }




}
