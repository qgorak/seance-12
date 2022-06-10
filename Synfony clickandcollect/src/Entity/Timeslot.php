<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * Timeslot
 *
 * @ORM\Table(name="timeslot", uniqueConstraints={@ORM\UniqueConstraint(name="slotDate", columns={"slotDate"})})
 * @ORM\Entity
 */
class Timeslot
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
     * @ORM\Column(name="slotDate", type="datetime", nullable=false)
     */
    private $slotdate;

    /**
     * @var bool
     *
     * @ORM\Column(name="full", type="boolean", nullable=false)
     */
    private $full = '0';

    /**
     * @var bool
     *
     * @ORM\Column(name="expired", type="boolean", nullable=false)
     */
    private $expired = '0';

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getSlotdate(): ?\DateTimeInterface
    {
        return $this->slotdate;
    }

    public function setSlotdate(\DateTimeInterface $slotdate): self
    {
        $this->slotdate = $slotdate;

        return $this;
    }

    public function isFull(): ?bool
    {
        return $this->full;
    }

    public function setFull(bool $full): self
    {
        $this->full = $full;

        return $this;
    }

    public function isExpired(): ?bool
    {
        return $this->expired;
    }

    public function setExpired(bool $expired): self
    {
        $this->expired = $expired;

        return $this;
    }


}
