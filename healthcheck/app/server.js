import express from 'express';
import {v4 as uuidv4} from 'uuid';


const app=express();
app.use(express.json());
app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true});
});
app.post('/trade/place', (req, res) => {
    const id = uuidv4();
    res.status(200).json({status: 'accepted', id});
})

const port = process.env.PORT || 8080;
app.listen(port, () => console.log('listening on $(port)'));
