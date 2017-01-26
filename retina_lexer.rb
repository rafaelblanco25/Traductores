class Doble_list
	def initialize
		@head=@tail=nil
	end 
	def add(id, linea, columna, clase)
		node=clase.new(id,linea,columna)
		node.act_next(@head) unless @head.nil?
		@head.act_prev(node) unless @head.nil?
		@head=node unless @head.nil?
		@tail=node if @tail.nil?
		@head=node if @head.nil?
	end 
	def head
		@head
	end
	def tail
		@tail
	end
	def to_s
		node=@tail
		while node!=nil
			puts "linea #{node.linea}, columna #{node.columna}: #{node.to_s} '#{node.id}'"
			node=node.prev
		end
		puts "Documento sin caracteres" if @tail.nil?
	end
end 

class Token
	def initialize(id,linea,columna)
		@id=id
		@linea=linea
		@columna=columna
		@next=nil
		@prev=nil
		@nombre=self.obtener_nombre
	end
	def act_next(node)
		@next=node
	end 
	def obtener_nombre
		nil
	end
	def act_prev(node)
		@prev=node
	end 
	def next
		@next
	end
	def prev
		@prev
	end
	def linea
		@linea
	end
	def columna
		@columna
	end
	def id
		@id
	end
	def tipo
		self.class
	end
	def to_s
    	@nombre
  end
end

$Token = {
	Tipodedatos: /\A(boolean|number)\b/,
	OperadoresLogicos: /\A(not|and|or)\b/,
	LiteralBoleano: /\A(true|false)\b/,
	PalabraReservada: /\A(program|with|do|while|if|end|repeat|times)\b/,
	Identificadores: /\A[a-z]\w*/,
	OperadoresComparacion_binarios: /\A(\/=|>=|<=|==)/,
	OperadoresAritmeticos: /\A(-|\*|\/|%|\+|div\b|mod\b)/,
	OperadoresComparacion_unarios: /\A(=|<|>)/,
	Signo: /\A(\(|\)|;)/,
	Number: /\A[0-9]+(.[0-9]+){0,1}/
}

class Tipodedatos < Token
	def obtener_nombre
		@nombre="tipo de datos"
	end
end

class OperadoresLogicos < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class PalabraReservada < Token
	def obtener_nombre
		@nombre="palabra reservada"
	end
end

class Identificadores < Token
	def obtener_nombre
		@nombre="identificador"
	end
end

class LiteralBoleano < Token
	def obtener_nombre
		@nombre="literal boleano"
	end
end

class OperadoresComparacion_binarios < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class OperadoresAritmeticos < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class OperadoresComparacion_unarios < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class Signo < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class Number < Token
	def obtener_nombre
		@nombre="literal numerico"
	end
end

class Inesperado < Token
	def obtener_nombre
		@nombre="caracter inesperado"
	end
end

class Lexer 
	def initialize 
		@lista=Doble_list.new								#Lista que contiene los tokens reconocidos
		@listaerror=Doble_list.new							#Lista que contiene los caracteres no admitidos
	end
	def eliminar_espacios_sin_caracter(linea, count)
		linea=~/\A\s*/
		c=count
		for i in(0..($&.length-1))
			if linea[i]=~/\t/
				c=c+4
			else 
				c=c+1
			end
		end
		linea=~/\A\s*/
		return [$',c]
	end 
	def catch_lexeme(fila,linea)
		linea=linea.sub(/#.*$/,"")													#Elimina los comentarios de la linea, si existen
		count=1
		linea,count=self.eliminar_espacios_sin_caracter(linea,count)				#Obtiene el string sin espacios en blanco al inicio
		while !linea.empty?
			error=true
			$Token.each do |key,value|												#Busqueda de expresión regular que corresponde al token
				if linea=~value
					clase=Object::const_get(key)
					@lista.add($&,fila, count, clase)
					count=count+$&.length
					linea=$'
					linea,count=self.eliminar_espacios_sin_caracter(linea, count)
					error=false
					break
				end
			end
			if error
				if linea=~/\A[A-Z]\w*/
					@listaerror.add($&,fila,count,Inesperado)
					count=count+$&.length
					linea=$'
					linea,count=self.eliminar_espacios_sin_caracter(linea, count)
				else 																#Proceso cuando el caracter es inesperado
					@listaerror.add(linea[0],fila,count,Inesperado)
					count=count+1
					linea=linea[1..linea.length-1]
					linea,count=self.eliminar_espacios_sin_caracter(linea, count)
				end
			end
		end
	end 
	def to_s
		if @listaerror.head.nil?
			@lista.to_s
		else 
			@listaerror.to_s
		end
	end
end