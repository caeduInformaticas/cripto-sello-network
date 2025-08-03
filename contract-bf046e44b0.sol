 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CriptoSello is ERC721, ERC721URIStorage, ERC721Pausable, Ownable {
    enum TokenState { IN_NOTARY, VALIDATED, REGISTERED }
    mapping(uint256 => TokenState) public tokenStates;

    address public notary;
    address public ddrr;

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
        ERC721("CriptoSello", "CS")
        Ownable(initialOwner)
    {
        notary = initialOwner;
        ddrr = _ddrr;
    }

    // Cambiar DDRR si lo requiere el owner
    function setDDRR(address _ddrr) public onlyOwner {
        ddrr = _ddrr;
    }

    // Pausa y reanuda (solo Owner/Notaría)
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Mintea un NFT de propiedad con un tokenId único generado a partir de address, documentId y uri.
     * @param to Dirección de la notaría (beneficiario inicial del NFT)
     * @param documentId Identificador único del documento (ejemplo: número catastral, registro)
     * @param uri CID/IPFS con los metadatos de la propiedad
     * @return tokenId El identificador único del NFT generado (uint256)
     */
    function mintProperty(address to, uint256 documentId, string memory uri)
        public
        onlyNotary
        returns (uint256 tokenId)
    {
        // Genera tokenId como hash seguro
        tokenId = uint256(keccak256(abi.encodePacked(to, documentId, uri)));

        // Validar que no exista aún (usando try-catch con ownerOf)
        try this.ownerOf(tokenId) returns (address) {
            revert("La propiedad ya existe (tokenId duplicado)");
        } catch {
            // OK: tokenId no existe
        }

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenStates[tokenId] = TokenState.IN_NOTARY;
        return tokenId;
    }


    // Validar documentación (solo Notaría)
    function validateProperty(uint256 tokenId) public onlyNotary {
        require(tokenStates[tokenId] == TokenState.IN_NOTARY, "Solo propiedades en estado IN_NOTARY pueden validarse");
        tokenStates[tokenId] = TokenState.VALIDATED;
    }

    // Registrar propiedad final (solo DDRR)
    function registerProperty(uint256 tokenId, string memory newUri) public onlyDDRR {
        require(tokenStates[tokenId] == TokenState.VALIDATED, "Debe estar validada primero");
        _setTokenURI(tokenId, newUri);
        tokenStates[tokenId] = TokenState.REGISTERED;
    }

    // Consulta pública de información (devuelve propietario, estado y el CID/IPFS)
    function getPropertyInfo(uint256 tokenId) public view returns (
        address owner,
        TokenState state,
        string memory uri
    ) {
        owner = ownerOf(tokenId);
        state = tokenStates[tokenId];
        uri = tokenURI(tokenId);
    }

    // (Overrides obligatorios por Solidity)
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