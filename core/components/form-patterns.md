# Form Patterns

## 📝 React Hook Form + Zod Integration

### Base Form Pattern

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

// Schema definition
const formSchema = z.object({
  name: z.string().min(1, 'Nome é obrigatório'),
  email: z.string().email('Email inválido'),
});

type FormData = z.infer<typeof formSchema>;

interface BaseFormProps {
  defaultValues?: Partial<FormData>;
  onSubmit: (data: FormData) => void;
  isLoading?: boolean;
  submitText?: string;
}

export function BaseForm({
  defaultValues,
  onSubmit,
  isLoading = false,
  submitText = 'Salvar'
}: BaseFormProps) {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues,
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Nome</FormLabel>
              <FormControl>
                <Input placeholder="Digite o nome" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input
                  type="email"
                  placeholder="Digite o email"
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={isLoading}>
          {isLoading ? 'Salvando...' : submitText}
        </Button>
      </form>
    </Form>
  );
}
```

## 🛠️ Complex Form Example

### Employee Form

```typescript
// services/employees/schemas/employee-schema.ts
export const employeeSchema = z.object({
  name: z.string().min(1, 'Nome é obrigatório'),
  email: z.string().email('Email inválido'),
  role: z.string().min(1, 'Função é obrigatória'),
  phone: z.string().optional(),
  status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
});

export type CreateEmployeeInput = z.infer<typeof employeeSchema>;

// _components/employee-form.tsx
import { employeeSchema, CreateEmployeeInput } from '@/services/employees/schemas';

interface EmployeeFormProps {
  defaultValues?: Partial<CreateEmployeeInput>;
  onSubmit: (data: CreateEmployeeInput) => void;
  isLoading?: boolean;
  submitText?: string;
}

export function EmployeeForm({
  defaultValues,
  onSubmit,
  isLoading = false,
  submitText = 'Salvar Funcionário'
}: EmployeeFormProps) {
  const form = useForm<CreateEmployeeInput>({
    resolver: zodResolver(employeeSchema),
    defaultValues,
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Nome *</FormLabel>
                <FormControl>
                  <Input placeholder="Nome do funcionário" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Email *</FormLabel>
                <FormControl>
                  <Input
                    type="email"
                    placeholder="email@empresa.com"
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="role"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Função *</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger>
                      <SelectValue placeholder="Selecione a função" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    <SelectItem value="MANAGER">Gerente</SelectItem>
                    <SelectItem value="OPERATOR">Operador</SelectItem>
                    <SelectItem value="TECHNICIAN">Técnico</SelectItem>
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="phone"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Telefone</FormLabel>
                <FormControl>
                  <Input
                    placeholder="(11) 99999-9999"
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
        </div>

        <FormField
          control={form.control}
          name="status"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Status</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="ACTIVE">Ativo</SelectItem>
                  <SelectItem value="INACTIVE">Inativo</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex justify-end space-x-4">
          <Button
            type="button"
            variant="outline"
            onClick={() => window.history.back()}
          >
            Cancelar
          </Button>
          <Button type="submit" disabled={isLoading}>
            {isLoading ? 'Salvando...' : submitText}
          </Button>
        </div>
      </form>
    </Form>
  );
}
```

## 🔧 Advanced Form Patterns

### Form with Dependencies

```typescript
interface SupplierFormProps {
  defaultValues?: Partial<CreateSupplierInput>;
  categories: SupplierCategory[];
  onSubmit: (data: CreateSupplierInput) => void;
  isLoading?: boolean;
}

export function SupplierForm({
  defaultValues,
  categories,
  onSubmit,
  isLoading
}: SupplierFormProps) {
  const form = useForm<CreateSupplierInput>({
    resolver: zodResolver(supplierSchema),
    defaultValues,
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        {/* Regular fields */}

        {/* Multi-select for categories */}
        <FormField
          control={form.control}
          name="categoryIds"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Categorias *</FormLabel>
              <FormControl>
                <MultiSelect<SupplierCategory>
                  items={categories}
                  getItemValue={(category) => category.id}
                  getItemLabel={(category) => category.name}
                  placeholder="Selecione as categorias"
                  searchPlaceholder="Buscar categorias..."
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
```

### Form with Dynamic Fields

```typescript
export function MachineryForm({ onSubmit, isLoading }: FormProps) {
  const form = useForm<CreateMachineryInput>({
    resolver: zodResolver(machinerySchema),
    defaultValues: {
      maintenanceSchedule: [{ type: '', intervalDays: 30 }]
    },
  });

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: "maintenanceSchedule"
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        {/* Static fields */}

        {/* Dynamic maintenance schedule */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <Label>Cronograma de Manutenção</Label>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => append({ type: '', intervalDays: 30 })}
            >
              <Plus className="h-4 w-4 mr-2" />
              Adicionar
            </Button>
          </div>

          {fields.map((field, index) => (
            <div key={field.id} className="flex gap-4 items-end">
              <FormField
                control={form.control}
                name={`maintenanceSchedule.${index}.type`}
                render={({ field }) => (
                  <FormItem className="flex-1">
                    <FormControl>
                      <Input placeholder="Tipo de manutenção" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name={`maintenanceSchedule.${index}.intervalDays`}
                render={({ field }) => (
                  <FormItem className="w-32">
                    <FormControl>
                      <Input
                        type="number"
                        placeholder="Dias"
                        {...field}
                        onChange={(e) => field.onChange(parseInt(e.target.value))}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => remove(index)}
                disabled={fields.length === 1}
              >
                <Trash className="h-4 w-4" />
              </Button>
            </div>
          ))}
        </div>
      </form>
    </Form>
  );
}
```

### Form with External API Integration

```typescript
export function AddressForm({ onSubmit }: FormProps) {
  const [isLoadingZipCode, setIsLoadingZipCode] = useState(false);

  const form = useForm<AddressInput>({
    resolver: zodResolver(addressSchema),
  });

  const zipCode = form.watch('zipCode');

  // Auto-fill address based on zip code
  useEffect(() => {
    const fetchAddress = async () => {
      if (zipCode && zipCode.length === 8) {
        setIsLoadingZipCode(true);
        try {
          const response = await fetch(`/api/zipcode/${zipCode}`);
          const data = await response.json();

          if (data.success) {
            form.setValue('address', data.address);
            form.setValue('neighborhood', data.neighborhood);
            form.setValue('city', data.city);
            form.setValue('state', data.state);
          }
        } catch (error) {
          console.error('Error fetching address:', error);
        } finally {
          setIsLoadingZipCode(false);
        }
      }
    };

    fetchAddress();
  }, [zipCode, form]);

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="zipCode"
          render={({ field }) => (
            <FormItem>
              <FormLabel>CEP</FormLabel>
              <FormControl>
                <div className="relative">
                  <Input
                    placeholder="00000-000"
                    {...field}
                  />
                  {isLoadingZipCode && (
                    <Loader2 className="absolute right-3 top-3 h-4 w-4 animate-spin" />
                  )}
                </div>
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        {/* Auto-filled fields */}
        <FormField
          control={form.control}
          name="address"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Endereço</FormLabel>
              <FormControl>
                <Input placeholder="Endereço" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
```

## 🎨 Form UI Patterns

### Loading States

```typescript
<Button type="submit" disabled={isLoading}>
  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
  {isLoading ? 'Salvando...' : submitText}
</Button>
```

### Required Field Indicator

```typescript
<FormLabel>
  Nome <span className="text-red-500">*</span>
</FormLabel>
```

### Form Actions

```typescript
<div className="flex justify-end space-x-4 pt-6">
  <Button
    type="button"
    variant="outline"
    onClick={() => router.back()}
    disabled={isLoading}
  >
    Cancelar
  </Button>
  <Button type="submit" disabled={isLoading}>
    {isLoading ? 'Salvando...' : submitText}
  </Button>
</div>
```

## 🔍 Validation Patterns

### Custom Validation

```typescript
const customSchema = z
  .object({
    password: z.string().min(8, "Mínimo 8 caracteres"),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Senhas não coincidem",
    path: ["confirmPassword"],
  });
```

### Conditional Validation

```typescript
const conditionalSchema = z
  .object({
    type: z.enum(["EMPLOYEE", "CONTRACTOR"]),
    employeeId: z.string().optional(),
    contractorInfo: z
      .object({
        company: z.string(),
        contract: z.string(),
      })
      .optional(),
  })
  .refine(
    (data) => {
      if (data.type === "EMPLOYEE") {
        return !!data.employeeId;
      }
      return !!data.contractorInfo;
    },
    {
      message: "Informações obrigatórias baseadas no tipo",
    },
  );
```

## 🎯 Form Best Practices

### ✅ Do's

- Use Zod schemas para validação
- Implemente loading states nos buttons
- Forneça feedback visual para campos obrigatórios
- Use TypeScript types gerados do schema
- Implemente auto-save quando apropriado
- Valide no cliente e servidor

### ❌ Don'ts

- Não implemente mutations no form component
- Não faça queries dentro do form
- Não ignore estados de loading
- Não esqueça de tratar erros de validação
- Não use validação apenas no cliente
