# INSTRUCCIONES 

1. Levantar una instancia IAM temporal de KodeKloud y obtener el ACCESS_KEY y el SECRET_KEY

2. Entrar al panel de EC2 y a la sección de **Key pairs** para colocar la key pair **terraform_ec2** por que el manifest me pide este key name

3. Correr los comandos:

  ```bash
    terraform init
  ```

```bash
  terraform plan -out=tfplan
  ```

  ```bash
    terraform apply --auto-approve tfplan
  ```
