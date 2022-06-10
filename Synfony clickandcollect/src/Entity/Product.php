<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

/**
 * Product
 *
 * @ORM\Table(name="product", indexes={@ORM\Index(name="idSection", columns={"idSection"}), @ORM\Index(name="name", columns={"name"}), @ORM\Index(name="comments", columns={"comments"})})
 * @ORM\Entity
 */
class Product
{
    /**
     * @var int
     *
     * @ORM\Column(name="id", type="integer", nullable=false)
     * @ORM\Id
     * @ORM\GeneratedValue(strategy="IDENTITY")
     */
    private $id;

    /**
     * @var string
     *
     * @ORM\Column(name="name", type="string", length=255, nullable=false)
     */
    private $name;

    /**
     * @var string|null
     *
     * @ORM\Column(name="comments", type="text", length=65535, nullable=true, options={"default"="NULL"})
     */
    private $comments = 'NULL';

    /**
     * @var int
     *
     * @ORM\Column(name="stock", type="integer", nullable=false)
     */
    private $stock;

    /**
     * @var string|null
     *
     * @ORM\Column(name="image", type="text", length=65535, nullable=true, options={"default"="NULL"})
     */
    private $image = 'NULL';

    /**
     * @var string
     *
     * @ORM\Column(name="price", type="decimal", precision=6, scale=2, nullable=false)
     */
    private $price;

    /**
     * @var string
     *
     * @ORM\Column(name="promotion", type="decimal", precision=6, scale=2, nullable=false)
     */
    private $promotion;

    /**
     * @var \Section
     *
     * @ORM\ManyToOne(targetEntity="Section")
     * @ORM\JoinColumns({
     *   @ORM\JoinColumn(name="idSection", referencedColumnName="id")
     * })
     */
    private $idsection;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\ManyToMany(targetEntity="Product", mappedBy="idassoproduct")
     */
    private $idproduct;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\ManyToMany(targetEntity="Basket", mappedBy="idproduct")
     */
    private $idbasket;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\ManyToMany(targetEntity="Order", mappedBy="idproduct")
     */
    private $idorder;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\ManyToMany(targetEntity="Product", inversedBy="idproduct")
     * @ORM\JoinTable(name="pack",
     *   joinColumns={
     *     @ORM\JoinColumn(name="idProduct", referencedColumnName="id")
     *   },
     *   inverseJoinColumns={
     *     @ORM\JoinColumn(name="idPack", referencedColumnName="id")
     *   }
     * )
     */
    private $idpack;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\OneToMany(targetEntity="Orderdetail", mappedBy="product")
     *  @ORM\JoinColumn(name="idProduct", referencedColumnName="id")
     */
    private $orderdetails;

    /**
     * Constructor
     */
    public function __construct()
    {
        $this->idproduct = new \Doctrine\Common\Collections\ArrayCollection();
        $this->idbasket = new \Doctrine\Common\Collections\ArrayCollection();
        $this->idorder = new \Doctrine\Common\Collections\ArrayCollection();
        $this->idpack = new \Doctrine\Common\Collections\ArrayCollection();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): ?string
    {
        return $this->name;
    }

    public function setName(string $name): self
    {
        $this->name = $name;

        return $this;
    }

    public function getComments(): ?string
    {
        return $this->comments;
    }

    public function setComments(?string $comments): self
    {
        $this->comments = $comments;

        return $this;
    }

    public function getStock(): ?int
    {
        return $this->stock;
    }

    public function setStock(int $stock): self
    {
        $this->stock = $stock;

        return $this;
    }

    public function getImage(): ?string
    {
        return $this->image;
    }

    public function setImage(?string $image): self
    {
        $this->image = $image;

        return $this;
    }

    public function getPrice(): ?string
    {
        return $this->price;
    }

    public function setPrice(string $price): self
    {
        $this->price = $price;

        return $this;
    }

    public function getPromotion(): ?string
    {
        return $this->promotion;
    }

    public function setPromotion(string $promotion): self
    {
        $this->promotion = $promotion;

        return $this;
    }

    public function getIdsection(): ?Section
    {
        return $this->idsection;
    }

    public function setIdsection(?Section $idsection): self
    {
        $this->idsection = $idsection;

        return $this;
    }

    /**
     * @return Collection<int, Product>
     */
    public function getIdproduct(): Collection
    {
        return $this->idproduct;
    }

    public function addIdproduct(Product $idproduct): self
    {
        if (!$this->idproduct->contains($idproduct)) {
            $this->idproduct[] = $idproduct;
            $idproduct->addIdassoproduct($this);
        }

        return $this;
    }

    public function removeIdproduct(Product $idproduct): self
    {
        if ($this->idproduct->removeElement($idproduct)) {
            $idproduct->removeIdassoproduct($this);
        }

        return $this;
    }

    /**
     * @return Collection<int, Basket>
     */
    public function getIdbasket(): Collection
    {
        return $this->idbasket;
    }

    public function addIdbasket(Basket $idbasket): self
    {
        if (!$this->idbasket->contains($idbasket)) {
            $this->idbasket[] = $idbasket;
            $idbasket->addIdproduct($this);
        }

        return $this;
    }

    public function removeIdbasket(Basket $idbasket): self
    {
        if ($this->idbasket->removeElement($idbasket)) {
            $idbasket->removeIdproduct($this);
        }

        return $this;
    }

    /**
     * @return Collection<int, Order>
     */
    public function getIdorder(): Collection
    {
        return $this->idorder;
    }

    public function addIdorder(Order $idorder): self
    {
        if (!$this->idorder->contains($idorder)) {
            $this->idorder[] = $idorder;
            $idorder->addIdproduct($this);
        }

        return $this;
    }

    public function removeIdorder(Order $idorder): self
    {
        if ($this->idorder->removeElement($idorder)) {
            $idorder->removeIdproduct($this);
        }

        return $this;
    }

    /**
     * @return Collection<int, Product>
     */
    public function getIdpack(): Collection
    {
        return $this->idpack;
    }

    public function addIdpack(Product $idpack): self
    {
        if (!$this->idpack->contains($idpack)) {
            $this->idpack[] = $idpack;
        }

        return $this;
    }

    public function removeIdpack(Product $idpack): self
    {
        $this->idpack->removeElement($idpack);

        return $this;
    }

}
