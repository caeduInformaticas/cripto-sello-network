// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts@5.3.0/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts@5.3.0/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.3.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts@5.3.0/access/Ownable.sol";

contract CriptoSello is ERC721, ERC721URIStorage, ERC721Pausable, Ownable {
     // --- Estados de los tokens (propiedades) ---
    uint256 private _nextTokenId = 1;
    enum TokenState { IN_NOTARY, VALIDATED, REGISTERED }
    mapping(uint256 => TokenState) public tokenStates;

    // --- Roles ---
    address public notary; // Owner inicial = Notaría
    address public ddrr;   // DDRR (Registro de Derechos Reales)

    // --- Modificadores de permisos ---
    modifier onlyNotary() {
        require(msg.sender == notary, "Solo la Notaria puede ejecutar");
        _;
    }

    modifier onlyDDRR() {
        require(msg.sender == ddrr, "Solo DDRR puede ejecutar");
        _;
    }
    
    constructor(address initialOwner, address _ddrr)
        ERC721("CriptSello", "CS")
        Ownable(initialOwner)
    {
        notary = initialOwner;
        ddrr = _ddrr;
    }

    // --- Función para que el Owner cambie DDRR si lo requiere ---
    function setDDRR(address _ddrr) public onlyOwner {
        ddrr = _ddrr;
    }

    // --- Pausa y reanuda (solo Owner/Notaría) ---
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Crear nueva propiedad (solo Notaría) ---
    function mintProperty(address to, string memory uri)
        public
        onlyNotary
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++; // Aumenta para el siguiente mint
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenStates[tokenId] = TokenState.IN_NOTARY;
        return tokenId;
    }

    // --- Validar documentación (solo Notaría) ---
    function validateProperty(uint256 tokenId) public onlyNotary {
        require(tokenStates[tokenId] == TokenState.IN_NOTARY, "Solo propiedades en estado IN_NOTARY pueden validarse");
        tokenStates[tokenId] = TokenState.VALIDATED;
    }

    // --- Registrar propiedad final (solo DDRR) ---
    function registerProperty(uint256 tokenId, string memory newUri) public onlyDDRR {
        require(tokenStates[tokenId] == TokenState.VALIDATED, "Debe estar validada primero");
        _setTokenURI(tokenId, newUri);
        tokenStates[tokenId] = TokenState.REGISTERED;
    }

    // --- Consulta pública de información ---
    function getPropertyInfo(uint256 tokenId) public view returns (
        address owner,
        TokenState state,
        string memory uri
    ) {
        owner = ownerOf(tokenId);
        state = tokenStates[tokenId];
        uri = tokenURI(tokenId);
    }

    // --- Función compatible para transferencias (overrides necesarios) ---
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
