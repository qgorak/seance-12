<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

/**
 * Order
 *
 * @ORM\Table(name="`order`", indexes={@ORM\Index(name="idUser", columns={"idUser"}), @ORM\Index(name="idEmployee", columns={"idEmployee"}), @ORM\Index(name="idTimeslot", columns={"idTimeslot"})})
 * @ORM\Entity
 */
class Order
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
     * @var \DateTime
     *
     * @ORM\Column(name="dateCreation", type="datetime", nullable=false, options={"default"="current_timestamp()"})
     */
    private $datecreation = 'current_timestamp()';

    /**
     * @var string
     *
     * @ORM\Column(name="status", type="string", length=100, nullable=false)
     */
    private $status;

    /**
     * @var string
     *
     * @ORM\Column(name="amount", type="decimal", precision=6, scale=2, nullable=false)
     */
    private $amount;

    /**
     * @var string
     *
     * @ORM\Column(name="toPay", type="decimal", precision=6, scale=2, nullable=false)
     */
    private $topay;

    /**
     * @var int
     *
     * @ORM\Column(name="itemsNumber", type="integer", nullable=false)
     */
    private $itemsnumber;

    /**
     * @var int
     *
     * @ORM\Column(name="missingNumber", type="integer", nullable=false)
     */
    private $missingnumber;

    /**
     * @var \User
     *
     * @ORM\ManyToOne(targetEntity="User")
     * @ORM\JoinColumns({
     *   @ORM\JoinColumn(name="idUser", referencedColumnName="id")
     * })
     */
    private $iduser;

    /**
     * @var \Timeslot
     *
     * @ORM\ManyToOne(targetEntity="Timeslot")
     * @ORM\JoinColumns({
     *   @ORM\JoinColumn(name="idTimeslot", referencedColumnName="id")
     * })
     */
    private $idtimeslot;

    /**
     * @var \Employee
     *
     * @ORM\ManyToOne(targetEntity="Employee")
     * @ORM\JoinColumns({
     *   @ORM\JoinColumn(name="idEmployee", referencedColumnName="id")
     * })
     */
    private $idemployee;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\ManyToMany(targetEntity="Product", inversedBy="idorder", fetch="EXTRA_LAZY")
     * @ORM\JoinTable(name="orderdetail",
     *   joinColumns={
     *     @ORM\JoinColumn(name="idOrder", referencedColumnName="id")
     *   },
     *   inverseJoinColumns={
     *     @ORM\JoinColumn(name="idProduct", referencedColumnName="id")
     *   }
     * )
     */
    private $idproduct;

    /**
     * @var \Doctrine\Common\Collections\Collection
     *
     * @ORM\OneToMany(targetEntity="Orderdetail", mappedBy="order")
     *  @ORM\JoinColumn(name="idOrder", referencedColumnName="id")
     */
    private $orderdetails;

    /**
     * Constructor
     */
    public function __construct()
    {
        $this->idproduct = new \Doctrine\Common\Collections\ArrayCollection();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getDatecreation(): ?\DateTimeInterface
    {
        return $this->datecreation;
    }

    public function setDatecreation(\DateTimeInterface $datecreation): self
    {
        $this->datecreation = $datecreation;

        return $this;
    }

    public function getStatus(): ?string
    {
        return $this->status;
    }

    public function setStatus(string $status): self
    {
        $this->status = $status;

        return $this;
    }

    public function getAmount(): ?string
    {
        return $this->amount;
    }

    public function setAmount(string $amount): self
    {
        $this->amount = $amount;

        return $this;
    }

    public function getTopay(): ?string
    {
        return $this->topay;
    }

    public function setTopay(string $topay): self
    {
        $this->topay = $topay;

        return $this;
    }

    public function getItemsnumber(): ?int
    {
        return $this->itemsnumber;
    }

    public function setItemsnumber(int $itemsnumber): self
    {
        $this->itemsnumber = $itemsnumber;

        return $this;
    }

    public function getMissingnumber(): ?int
    {
        return $this->missingnumber;
    }

    public function setMissingnumber(int $missingnumber): self
    {
        $this->missingnumber = $missingnumber;

        return $this;
    }

    public function getIduser(): ?User
    {
        return $this->iduser;
    }

    public function setIduser(?User $iduser): self
    {
        $this->iduser = $iduser;

        return $this;
    }

    public function getIdtimeslot(): ?Timeslot
    {
        return $this->idtimeslot;
    }

    public function setIdtimeslot(?Timeslot $idtimeslot): self
    {
        $this->idtimeslot = $idtimeslot;

        return $this;
    }

    public function getIdemployee(): ?Employee
    {
        return $this->idemployee;
    }

    public function setIdemployee(?Employee $idemployee): self
    {
        $this->idemployee = $idemployee;

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
        }

        return $this;
    }

    public function removeIdproduct(Product $idproduct): self
    {
        $this->idproduct->removeElement($idproduct);

        return $this;
    }

    /**
     * @return Collection
     */
    public function getOrderdetails(): Collection
    {
        return $this->orderdetails;
    }

    /**
     * @param Collection $orderdetails
     */
    public function setOrderdetails(Collection $orderdetails): void
    {
        $this->orderdetails = $orderdetails;
    }




}
