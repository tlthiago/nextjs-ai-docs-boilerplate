## **Transações**

### **Operações Atômicas**

```typescript
// services/suppliers/create-with-categories.ts
export async function createSupplierWithCategories(
  supplierData: CreateSupplierInput,
  categoryIds: string[],
  userId: string,
) {
  return await prisma.$transaction(async (tx) => {
    // 1. Criar supplier
    const supplier = await tx.supplier.create({
      data: {
        ...supplierData,
        createdById: userId,
        status: "ACTIVE",
      },
    });

    // 2. Criar relacionamentos com categorias
    await tx.supplierCategoryMapping.createMany({
      data: categoryIds.map((categoryId) => ({
        supplierId: supplier.id,
        supplierCategoryId: categoryId,
      })),
    });

    // 3. Retornar supplier com categorias
    return await tx.supplier.findUnique({
      where: { id: supplier.id },
      include: {
        categories: {
          include: { supplierCategory: true },
        },
      },
    });
  });
}
```